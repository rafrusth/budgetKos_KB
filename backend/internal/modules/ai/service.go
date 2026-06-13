package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"strings"
	"time"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type Service interface {
	GetAdvice(message string, localCtx LocalContext) (map[string]interface{}, error)
}

type service struct {
	txService  transaction.Service
	catService category.Service
}

func NewService(txService transaction.Service, catService category.Service) Service {
	return &service{txService, catService}
}

// Struct untuk mem-parsing balasan JSON dari Gemini
type GeminiResponse struct {
	Reply               string                 `json:"reply"`
	CreatedTransactions []GeminiTransaction    `json:"created_transactions"`
	CreatedCategories   []GeminiCategoryCreate `json:"created_categories"`
	UpdatedCategories   []GeminiCategoryUpdate `json:"updated_categories"`
	DeletedCategories   []uint                 `json:"deleted_categories"`
}

type GeminiTransaction struct {
	Title      string  `json:"title"`
	Amount     float64 `json:"amount"`
	Type       string  `json:"type"` // "income" or "expense"
	CategoryID uint    `json:"category_id"`
}

type GeminiCategoryCreate struct {
	Name  string `json:"name"`
	Type  string `json:"type"`  // "income" or "expense"
	Icon  string `json:"icon"`  // Optional
	Color string `json:"color"` // Optional hex color
}

type GeminiCategoryUpdate struct {
	ID    uint   `json:"id"`
	Name  string `json:"name"`
	Type  string `json:"type"`  // "income" or "expense"
	Icon  string `json:"icon"`  // Optional
	Color string `json:"color"` // Optional hex color
}

func (s *service) GetAdvice(message string, localCtx LocalContext) (map[string]interface{}, error) {
	ctx := context.Background()
	apiKey := config.AppConfig.GeminiAPIKey
	if apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY is not set")
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, err
	}
	defer client.Close()

	// 1. Fetch categories
	cats, err := s.catService.GetAllCategories()
	var catContext string
	if err == nil && len(cats) > 0 {
		var catLines []string
		for _, cat := range cats {
			catLines = append(catLines, fmt.Sprintf("- ID: %d | Name: %s | Type: %s", cat.ID, cat.Name, cat.Type))
		}
		catContext = "\n\nDaftar Kategori yang Valid:\n" + strings.Join(catLines, "\n")
	}

	// 2. Gunakan data dari LocalContext (karena frontend pakai SQLite lokal)
	var txContext string
	if len(localCtx.RecentTransactions) > 0 {
		var txLines []string
		for _, tx := range localCtx.RecentTransactions {
			// tx is map[string]interface{}
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

		// Burn-rate calculation
		now := time.Now()
		dayOfMonth := now.Day()
		daysRemaining := localCtx.DaysRemainingInMonth
		if daysRemaining <= 0 {
			// Fallback: calculate from current date
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
		txContext = "\n\nSaat ini pengguna belum memiliki data transaksi apapun."
	}

	model := client.GenerativeModel("gemini-1.5-flash-8b")
	model.ResponseMIMEType = "application/json"

	// Build location context
	var locationContext string
	if localCtx.CampusLocation != "" {
		locationContext = fmt.Sprintf("\n\nLOKASI PENGGUNA: %s\nSELALU berikan rekomendasi harga, tempat makan, dan estimasi biaya hidup sesuai standar area %s. Jangan gunakan harga kota lain.", localCtx.CampusLocation, localCtx.CampusLocation)
	}

	systemPrompt := `Kamu adalah konsultan keuangan pribadi cerdas dan suportif untuk mahasiswa/anak kos.
Gunakan bahasa gaul/santai khas anak muda Indonesia. Usahakan ringkas namun solutif.
SELALU rujuk pada 'data keuangan riil' di bawah.

TUGAS PENTING (BURN-RATE):
Jika saldo pengguna menipis, WAJIB sebutkan burn-rate (rata-rata pengeluaran/hari) dan proyeksi kapan uang habis berdasarkan data Analisis Burn-Rate di bawah. Beri peringatan jika proyeksi kehabisan uang lebih cepat dari sisa hari di bulan ini.

TUGAS PENTING (OTOMASI TRANSAKSI & KATEGORI):
Jika pengguna meminta mencatat pengeluaran/pemasukan baru, WAJIB masukkan ke array "created_transactions".
ATURAN MEMILIH KATEGORI TRANSAKSI: Pilih "category_id" HANYA dari Daftar Kategori Valid. Kamu WAJIB menganalisis objek/barang dari transaksi tersebut secara logis untuk mencocokkan dengan kategori (misal: "nasi padang" -> ID kategori Makanan/Konsumsi, "pulpen" -> ID kategori ATK, "gojek" -> ID kategori Transportasi). Jangan asal tebak ID.
Jika pengguna meminta membuat, mengubah, atau menghapus KATEGORI, WAJIB masukkan ke array "created_categories", "updated_categories", atau "deleted_categories".
Untuk kategori baru, tipe harus "income" atau "expense", icon bisa emoji atau string icon, color bisa hex color.

Kamu WAJIB mengembalikan HANYA format JSON seperti ini (tanpa markdown blok):
{
  "reply": "teks balasan kamu ke pengguna",
  "created_transactions": [{"title": "makan nasi padang", "amount": 15000, "type": "expense", "category_id": 99}],
  "created_categories": [{"name": "Uang Jajan", "type": "income", "icon": "💰", "color": "#00FF00"}],
  "updated_categories": [{"id": 2, "name": "Bensin", "type": "expense", "icon": "🚗", "color": "#FF0000"}],
  "deleted_categories": [3]
}
Biarkan array kosong [] jika tidak ada aksi terkait.`

	model.SystemInstruction = &genai.Content{
		Parts: []genai.Part{genai.Text(systemPrompt + catContext + txContext + locationContext)},
	}

	// Build K-previous messages as multi-turn chat history
	var chatHistory []*genai.Content
	for _, h := range localCtx.ChatHistory {
		chatHistory = append(chatHistory, &genai.Content{
			Role:  "user",
			Parts: []genai.Part{genai.Text(h.Prompt)},
		})
		chatHistory = append(chatHistory, &genai.Content{
			Role:  "model",
			Parts: []genai.Part{genai.Text(h.Response)},
		})
	}

	// Use chat session with history for multi-turn conversation
	chat := model.StartChat()
	chat.History = chatHistory

	resp, err := chat.SendMessage(ctx, genai.Text(message))
	if err != nil {
		return nil, err
	}

	if len(resp.Candidates) > 0 && len(resp.Candidates[0].Content.Parts) > 0 {
		if textPart, ok := resp.Candidates[0].Content.Parts[0].(genai.Text); ok {
			rawJSON := string(textPart)
			// Remove markdown code blocks if AI still adds them despite instructions
			rawJSON = strings.TrimPrefix(rawJSON, "```json\n")
			rawJSON = strings.TrimSuffix(rawJSON, "\n```")
			rawJSON = strings.TrimSuffix(rawJSON, "```")

			var geminiResp GeminiResponse
			if err := json.Unmarshal([]byte(rawJSON), &geminiResp); err != nil {
				log.Printf("Failed to parse Gemini JSON: %v. Raw: %s", err, rawJSON)
				return nil, fmt.Errorf("failed to parse AI response: %v", err)
			}

			var createdRecords []transaction.Transaction
			var createdCats []category.Category
			var updatedCats []category.Category
			var deletedCats []uint

			// Execute transaction automation!
			for _, t := range geminiResp.CreatedTransactions {
				req := transaction.Transaction{
					Title:      t.Title,
					Amount:     t.Amount,
					Type:       t.Type,
					CategoryID: t.CategoryID,
					Date:       time.Now(),
					IsSynced:   true,
				}
				saved, err := s.txService.Create(req)
				if err == nil && saved != nil {
					// We need to fetch it again with Category joined to send back complete data
					fullSaved, _ := s.txService.GetByID(saved.ID)
					if fullSaved != nil {
						createdRecords = append(createdRecords, *fullSaved)
					} else {
						createdRecords = append(createdRecords, *saved)
					}
				}
			}

			// Execute category automation!
			for _, c := range geminiResp.CreatedCategories {
				req := category.Category{Name: c.Name, Type: c.Type, Icon: c.Icon, Color: c.Color}
				saved, err := s.catService.CreateCategory(req)
				if err == nil && saved != nil {
					createdCats = append(createdCats, *saved)
				}
			}

			for _, c := range geminiResp.UpdatedCategories {
				req := category.Category{Name: c.Name, Type: c.Type, Icon: c.Icon, Color: c.Color}
				updated, err := s.catService.UpdateCategory(c.ID, req)
				if err == nil && updated != nil {
					updatedCats = append(updatedCats, *updated)
				}
			}

			for _, id := range geminiResp.DeletedCategories {
				err := s.catService.DeleteCategory(id)
				if err == nil {
					deletedCats = append(deletedCats, id)
				}
			}

			result := map[string]interface{}{
				"reply":                geminiResp.Reply,
				"created_transactions": createdRecords,
				"created_categories":   createdCats,
				"updated_categories":   updatedCats,
				"deleted_categories":   deletedCats,
			}
			return result, nil
		}
	}

	return nil, fmt.Errorf("no valid response from Gemini")
}
