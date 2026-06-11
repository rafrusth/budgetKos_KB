package ai

import (
	"net/http"

	"budget_kos/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type ChatRequest struct {
	Message string `json:"message" binding:"required"`
}

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service}
}

func (h *Handler) Chat(c *gin.Context) {
	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Pesan tidak boleh kosong")
		return
	}

	reply, err := h.service.GetAdvice(req.Message)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Gagal mendapatkan respon dari AI: "+err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Berhasil", gin.H{
		"reply": reply,
	})
}
