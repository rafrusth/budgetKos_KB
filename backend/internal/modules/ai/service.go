package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
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
	Reply               string              `json:"reply"`
	CreatedTransactions []GeminiTransaction `json:"created_transactions"`
}

type GeminiTransaction struct {
	Title      string  `json:"title"`
	Amount     float64 `json:"amount"`
	Type       string  `json:"type"` // "income" or "expense"
	CategoryID uint    `json:"category_id"`
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
		
		txContext = fmt.Sprintf("\n\nData keuangan riil saat ini (dari HP pengguna):\nTotal Pemasukan: Rp %.0f\nTotal Pengeluaran: Rp %.0f\nSisa Saldo: Rp %.0f\n\nRiwayat Transaksi Terakhir:\n%s\n",
			totalPemasukan, totalPengeluaran, sisaSaldo, strings.Join(txLines, "\n"))
	} else {
		txContext = "\n\nSaat ini pengguna belum memiliki data transaksi apapun."
	}

	model := client.GenerativeModel("gemini-2.5-flash")
	model.ResponseMIMEType = "application/json"

	systemPrompt := `Kamu adalah konsultan keuangan pribadi cerdas dan suportif untuk mahasiswa/anak kos.
Gunakan bahasa gaul/santai khas anak muda Indonesia. Usahakan ringkas namun solutif.
SELALU rujuk pada 'data keuangan riil' di bawah.

TUGAS PENTING (OTOMASI):
Jika pengguna meminta kamu untuk mencatat pengeluaran atau pemasukan baru (misal: "makan 15 ribu", "dapat uang saku 1 juta"), KAMU WAJIB memasukkannya ke dalam array "created_transactions" di JSON balasan.
Pilih "category_id" HANYA dari Daftar Kategori Valid di bawah. Jangan mengarang category_id. Pastikan "type" hanya "income" atau "expense".

Kamu WAJIB mengembalikan HANYA format JSON seperti ini (tanpa markdown blok):
{
  "reply": "teks balasan kamu ke pengguna (misal: Oke udah dicatet ya! Sisa saldomu sekarang jadi...)",
  "created_transactions": [
    {
      "title": "judul transaksi",
      "amount": 15000,
      "type": "expense",
      "category_id": 1
    }
  ]
}
Biarkan array "created_transactions" kosong [] jika pengguna tidak meminta mencatat transaksi.`

	model.SystemInstruction = &genai.Content{
		Parts: []genai.Part{genai.Text(systemPrompt + catContext + txContext)},
	}

	resp, err := model.GenerateContent(ctx, genai.Text(message))
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
			// Execute automation!
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

			result := map[string]interface{}{
				"reply":                geminiResp.Reply,
				"created_transactions": createdRecords,
			}
			return result, nil
		}
	}

	return nil, fmt.Errorf("no valid response from Gemini")
}
