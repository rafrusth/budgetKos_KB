package ai

import (
	"context"
	"fmt"
	"strings"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/modules/transaction"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type Service interface {
	GetAdvice(message string) (string, error)
}

type service struct {
	txService transaction.Service
}

func NewService(txService transaction.Service) Service {
	return &service{txService}
}

func (s *service) GetAdvice(message string) (string, error) {
	ctx := context.Background()
	apiKey := config.AppConfig.GeminiAPIKey
	if apiKey == "" {
		return "", fmt.Errorf("GEMINI_API_KEY is not set")
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return "", err
	}
	defer client.Close()

	// Fetch transaction history to give context to Gemini
	txs, err := s.txService.GetAll()
	var txContext string
	if err == nil && len(txs) > 0 {
		var txLines []string
		var totalPemasukan float64
		var totalPengeluaran float64

		for _, tx := range txs {
			txLines = append(txLines, fmt.Sprintf("- %s: Rp %.0f (%s) - Kategori: %s - %s", tx.Date.Format("2006-01-02"), tx.Amount, tx.Type, tx.Category.Name, tx.Title))
			if strings.ToLower(tx.Type) == "income" || strings.ToLower(tx.Type) == "pemasukan" {
				totalPemasukan += tx.Amount
			} else {
				totalPengeluaran += tx.Amount
			}
		}

		txContext = fmt.Sprintf("\n\nBerikut adalah data keuangan riil pengguna saat ini yang diambil dari database:\nTotal Pemasukan: Rp %.0f\nTotal Pengeluaran: Rp %.0f\nSisa Saldo Saat Ini: Rp %.0f\n\nRiwayat Transaksi:\n%s\n",
			totalPemasukan, totalPengeluaran, totalPemasukan-totalPengeluaran, strings.Join(txLines, "\n"))
	} else {
		txContext = "\n\nSaat ini pengguna belum memiliki data transaksi apapun di database."
	}

	model := client.GenerativeModel("gemini-2.5-flash")

	systemPrompt := "Kamu adalah konsultan keuangan pribadi yang sangat cerdas, ramah, dan suportif khusus ditugaskan untuk membantu mahasiswa/anak kos. Berikan saran praktis, hemat, dan gunakan bahasa gaul/santai khas anak muda Indonesia. Jangan berikan respon yang terlalu panjang, usahakan ringkas namun solutif. SELALU rujuk pada 'data keuangan riil' yang diberikan di bawah ini saat memberikan analisis atau menjawab pertanyaan tentang uang, saldo, atau pengeluaran pengguna."
	model.SystemInstruction = &genai.Content{
		Parts: []genai.Part{genai.Text(systemPrompt + txContext)},
	}

	resp, err := model.GenerateContent(ctx, genai.Text(message))
	if err != nil {
		return "", err
	}

	if len(resp.Candidates) > 0 && len(resp.Candidates[0].Content.Parts) > 0 {
		if textPart, ok := resp.Candidates[0].Content.Parts[0].(genai.Text); ok {
			return string(textPart), nil
		}
	}

	return "", fmt.Errorf("no valid response from Gemini")
}
