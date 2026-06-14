package ai

import (
	"net/http"

	"budget_kos/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type ChatHistoryItem struct {
	Prompt   string `json:"prompt"`
	Response string `json:"response"`
}

type LocalContext struct {
	TotalIncome          float64                  `json:"total_income"`
	TotalExpense         float64                  `json:"total_expense"`
	RecentTransactions   []map[string]interface{} `json:"recent_transactions"`
	CampusLocation       string                   `json:"campus_location"`
	DaysRemainingInMonth int                      `json:"days_remaining_in_month"`
	ChatHistory          []ChatHistoryItem        `json:"chat_history"`
}

type ChatRequest struct {
	Message      string       `json:"message" binding:"required"`
	LocalContext LocalContext `json:"local_context"`
}

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service}
}

func (h *Handler) Chat(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		response.Error(c, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Pesan tidak boleh kosong")
		return
	}

	aiResult, err := h.service.GetAdvice(userID, req.Message, req.LocalContext)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Gagal mendapatkan respon dari AI: "+err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Berhasil", aiResult)
}
