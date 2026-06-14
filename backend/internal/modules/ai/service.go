package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"strings"
	"time"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
)

type Service interface {
	GetAdvice(userID, message string, localCtx LocalContext) (map[string]interface{}, error)
}

type service struct {
	txService  transaction.Service
	catService category.Service
}

func NewService(txService transaction.Service, catService category.Service) Service {
	return &service{txService, catService}
}

// Struct untuk mem-parsing balasan JSON dari Groq
type GroqAPIResponse struct {
	Reply               string                 `json:"reply"`
	CreatedTransactions []GeminiTransaction    `json:"created_transactions"`
	CreatedCategories   []GeminiCategoryCreate `json:"created_categories"`
	UpdatedCategories   []GeminiCategoryUpdate `json:"updated_categories"`
	DeletedCategories   []string               `json:"deleted_categories"`
}

type GeminiTransaction struct {
	Title      string  `json:"title"`
	Amount     float64 `json:"amount"`
	Type       string  `json:"type"` // "income" or "expense"
	CategoryID string  `json:"category_id"`
}

type GeminiCategoryCreate struct {
	Name  string `json:"name"`
	Type  string `json:"type"`  // "income" or "expense"
	Icon  string `json:"icon"`  // Optional
	Color string `json:"color"` // Optional hex color
}

type GeminiCategoryUpdate struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Type  string `json:"type"`  // "income" or "expense"
	Icon  string `json:"icon"`  // Optional
	Color string `json:"color"` // Optional hex color
}

// Request & Response structs untuk OpenAI-compatible API (Groq)
type GroqMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type GroqRequest struct {
	Model          string                 `json:"model"`
	Messages       []GroqMessage          `json:"messages"`
	ResponseFormat map[string]interface{} `json:"response_format,omitempty"`
}

type GroqRawResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func (s *service) GetAdvice(userID, message string, localCtx LocalContext) (map[string]interface{}, error) {
	apiKey := config.AppConfig.GroqAPIKey
	if apiKey == "" {
		return nil, fmt.Errorf("GROQ_API_KEY is not set")
	}

	// 1. Fetch categories
	cats, err := s.catService.GetAll(userID)
	var catContext string
	if err == nil && len(cats) > 0 {
		var catLines []string
		for _, cat := range cats {
			catLines = append(catLines, fmt.Sprintf("- ID: %s | Name: %s | Type: %s", cat.ID, cat.Name, cat.Type))
		}
		catContext = "\n\nDaftar Kategori yang Valid:\n" + strings.Join(catLines, "\n")
	}

	// 2. Gunakan data dari LocalContext (karena frontend pakai SQLite lokal)
	var txContext string
	if len(localCtx.RecentTransactions) > 0 {
		var txLines []string
		for _, tx := range localCtx.RecentTransactions {
			dateStr := ""
			if d, ok := tx["date"].(string); ok && len(d) >= 10 {
				dateStr = d[:10] // YYYY-MM-DD
			}
			amount := 0.0
			if amt, ok := tx["amount"].(float64); ok {
				amount = amt
			}
			txType, _ := tx["type"].(string)
			catName, _ := tx["category"].(string)
			title, _ := tx["title"].(string)

			txLines = append(txLines, fmt.Sprintf("- %s: Rp %.0f (%s) - Kategori: %s - %s", dateStr, amount, txType, catName, title))
		}

		totalPemasukan := localCtx.TotalIncome
		totalPengeluaran := localCtx.TotalExpense
		sisaSaldo := totalPemasukan - totalPengeluaran

		now := time.Now()
		dayOfMonth := now.Day()
		daysRemaining := localCtx.DaysRemainingInMonth
		if daysRemaining <= 0 {
			lastDay := time.Date(now.Year(), now.Month()+1, 0, 0, 0, 0, 0, now.Location())
			daysRemaining = lastDay.Day() - dayOfMonth
		}

		burnRate := 0.0
		if dayOfMonth > 0 {
			burnRate = totalPengeluaran / float64(dayOfMonth)
		}
		daysUntilBroke := 0.0
		if burnRate > 0 {
			daysUntilBroke = math.Floor(sisaSaldo / burnRate)
		}

		burnRateContext := fmt.Sprintf("\n\nAnalisis Burn-Rate:\n- Rata-rata pengeluaran per hari: Rp %.0f\n- Sisa hari di bulan ini: %d hari\n- Proyeksi hari uang habis: %.0f hari lagi (jika pola pengeluaran sama)\n- Proyeksi pengeluaran sampai akhir bulan: Rp %.0f\n",
			burnRate, daysRemaining, daysUntilBroke, burnRate*float64(daysRemaining))

		txContext = fmt.Sprintf("\n\nData keuangan riil saat ini (dari HP pengguna):\nTotal Pemasukan: Rp %.0f\nTotal Pengeluaran: Rp %.0f\nSisa Saldo: Rp %.0f\n\nRiwayat Transaksi Terakhir:\n%s\n",
			totalPemasukan, totalPengeluaran, sisaSaldo, strings.Join(txLines, "\n"))
		txContext += burnRateContext
	} else {
		txContext = fmt.Sprintf("\n\nData keuangan riil saat ini (dari HP pengguna):\nTotal Pemasukan: Rp %.0f\nTotal Pengeluaran: Rp %.0f\nSisa Saldo: Rp %.0f\n\nSaat ini pengguna belum memiliki data transaksi apapun.",
			localCtx.TotalIncome, localCtx.TotalExpense, localCtx.TotalIncome-localCtx.TotalExpense)
	}

	var locationContext string
	if localCtx.CampusLocation != "" {
		locationContext = fmt.Sprintf("\n\nLOKASI PENGGUNA: %s\nSELALU berikan rekomendasi harga, tempat makan, dan estimasi biaya hidup sesuai standar area %s. Jangan gunakan harga kota lain.", localCtx.CampusLocation, localCtx.CampusLocation)
	}

	systemPrompt := `Kamu adalah konsultan keuangan pribadi cerdas dan suportif untuk mahasiswa/anak kos.
Gunakan bahasa gaul/santai khas anak muda Indonesia. Usahakan ringkas namun solutif.
SELALU rujuk pada 'data keuangan riil' di bawah.

TUGAS PENTING (FORMAT NOMINAL RUPIAH):
DILARANG KERAS menggunakan singkatan untuk nominal uang seperti "K", "rb", atau "jt" di balasan chat.
WAJIB tuliskan angka penuh dengan format Rupiah yang baku menggunakan titik sebagai pemisah ribuan.
Contoh Benar: "Rp 1.500.000", "Rp 25.000"
Contoh Salah: "1.5 jt", "25rb", "25K", "1500000"

TUGAS PENTING (BURN-RATE):
Jika saldo pengguna menipis, WAJIB sebutkan burn-rate (rata-rata pengeluaran/hari) dan proyeksi kapan uang habis berdasarkan data Analisis Burn-Rate di bawah. Beri peringatan jika proyeksi kehabisan uang lebih cepat dari sisa hari di bulan ini.

TUGAS PENTING (OTOMASI TRANSAKSI & KATEGORI):
Jika pengguna meminta mencatat pengeluaran/pemasukan baru, WAJIB masukkan ke array "created_transactions".
Perhatikan penulisan angka dengan teliti: "rb" = ribu (x1.000), "jt" = juta (x1.000.000), "m" = miliar (x1.000.000.000). Contoh: "1000jt" berarti 1000 x 1.000.000 = 1.000.000.000 (Satu Miliar), BUKAN seratus juta.
ATURAN KATEGORI TRANSAKSI:
1. Jika "Daftar Kategori Valid" tersedia, pilih UUID "category_id" dari daftar tersebut yang paling cerdas & sesuai dengan jenis produk (contoh: "nasi padang" -> Makanan, "bensin" -> Transportasi). Jangan asal tebak UUID.
2. Jika daftar kosong atau tidak ada kategori yang cocok, kamu WAJIB membuat kategori baru yang sesuai secara cerdas ke dalam "created_categories". Gunakan nama kategori baru tersebut (string) sebagai isian "category_id" di "created_transactions".
Untuk kategori baru, tipe harus "income" atau "expense", icon bisa emoji, color bisa hex color.

Kamu WAJIB mengembalikan HANYA format JSON murni seperti ini (tanpa markdown blok, langsung JSON):
{
  "reply": "teks balasan kamu ke pengguna",
  "created_transactions": [{"title": "makan nasi padang", "amount": 15000, "type": "expense", "category_id": "Makanan"}],
  "created_categories": [{"name": "Uang Jajan", "type": "income", "icon": "💰", "color": "#00FF00"}],
  "updated_categories": [{"id": "uuid-dari-daftar-valid", "name": "Bensin", "type": "expense", "icon": "🚗", "color": "#FF0000"}],
  "deleted_categories": ["uuid-dari-daftar-valid"]
}
Biarkan array kosong [] jika tidak ada aksi terkait.`

	messages := []GroqMessage{
		{Role: "system", Content: systemPrompt + catContext + txContext + locationContext},
	}

	// Tambahkan riwayat chat sebelumnya
	for _, h := range localCtx.ChatHistory {
		messages = append(messages, GroqMessage{Role: "user", Content: h.Prompt})
		messages = append(messages, GroqMessage{Role: "assistant", Content: h.Response})
	}
	// Tambahkan pesan terbaru dari user
	messages = append(messages, GroqMessage{Role: "user", Content: message})

	reqBody := GroqRequest{
		Model:    "llama-3.3-70b-versatile",
		Messages: messages,
		ResponseFormat: map[string]interface{}{
			"type": "json_object",
		},
	}

	reqBytes, _ := json.Marshal(reqBody)

	// Panggil API Groq
	req, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/chat/completions", bytes.NewBuffer(reqBytes))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("groq api error: status %d body %s", resp.StatusCode, string(bodyBytes))
	}

	var groqResp GroqRawResponse
	if err := json.NewDecoder(resp.Body).Decode(&groqResp); err != nil {
		return nil, err
	}

	if len(groqResp.Choices) == 0 {
		return nil, fmt.Errorf("no response choices returned from Groq")
	}

	rawJSON := groqResp.Choices[0].Message.Content
	rawJSON = strings.TrimPrefix(rawJSON, "```json\n")
	rawJSON = strings.TrimSuffix(rawJSON, "\n```")
	rawJSON = strings.TrimSuffix(rawJSON, "```")

	var parsedResp GroqAPIResponse
	if err := json.Unmarshal([]byte(rawJSON), &parsedResp); err != nil {
		log.Printf("Failed to parse Groq JSON: %v. Raw: %s", err, rawJSON)
		return nil, fmt.Errorf("failed to parse AI response: %v", err)
	}

	var createdRecords []transaction.Transaction
	var createdCats []category.Category
	var updatedCats []category.Category
	var deletedCats []string

	// Execute category automation FIRST
	for _, c := range parsedResp.CreatedCategories {
		catReq := category.Category{Name: c.Name, Type: c.Type, Icon: c.Icon, Color: c.Color}
		saved, err := s.catService.Create(userID, catReq)
		if err == nil && saved != nil {
			createdCats = append(createdCats, *saved)
		}
	}

	// Execute transaction automation
	for _, t := range parsedResp.CreatedTransactions {
		found := false
		for _, cat := range cats {
			if cat.ID == t.CategoryID || strings.EqualFold(cat.Name, t.CategoryID) {
				t.CategoryID = cat.ID
				found = true
				break
			}
		}
		if !found {
			for _, cat := range createdCats {
				if cat.ID == t.CategoryID || strings.EqualFold(cat.Name, t.CategoryID) {
					t.CategoryID = cat.ID
					found = true
					break
				}
			}
		}
		if !found || len(t.CategoryID) != 36 {
			newCatName := t.CategoryID
			if newCatName == "" || newCatName == "1" || len(newCatName) > 20 {
				newCatName = "Umum"
			}
			newCat := category.Category{Name: newCatName, Type: t.Type, Icon: "📌", Color: "#808080"}
			savedCat, _ := s.catService.Create(userID, newCat)
			if savedCat != nil {
				t.CategoryID = savedCat.ID
				createdCats = append(createdCats, *savedCat)
			}
		}

		txReq := transaction.Transaction{
			Title:      t.Title,
			Amount:     t.Amount,
			Type:       t.Type,
			CategoryID: t.CategoryID,
			Date:       time.Now(),
			IsSynced:   true,
		}
		saved, err := s.txService.Create(userID, txReq)
		if err == nil && saved != nil {
			fullSaved, _ := s.txService.GetByID(userID, saved.ID)
			if fullSaved != nil {
				createdRecords = append(createdRecords, *fullSaved)
			} else {
				createdRecords = append(createdRecords, *saved)
			}
		}
	}

	for _, c := range parsedResp.UpdatedCategories {
		catReq := category.Category{Name: c.Name, Type: c.Type, Icon: c.Icon, Color: c.Color}
		updated, err := s.catService.Update(userID, c.ID, catReq)
		if err == nil && updated != nil {
			updatedCats = append(updatedCats, *updated)
		}
	}

	for _, id := range parsedResp.DeletedCategories {
		err := s.catService.Delete(userID, id)
		if err == nil {
			deletedCats = append(deletedCats, id)
		}
	}

	result := map[string]interface{}{
		"reply":                parsedResp.Reply,
		"created_transactions": createdRecords,
		"created_categories":   createdCats,
		"updated_categories":   updatedCats,
		"deleted_categories":   deletedCats,
	}
	return result, nil
}
