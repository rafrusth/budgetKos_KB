package transaction

import (
	"net/http"
	"budget_kos/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service}
}

func (h *Handler) GetAll(c *gin.Context) {
	userID := c.GetString("user_id")
	txs, err := h.service.GetAll(userID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get transactions")
		return
	}
	response.Success(c, http.StatusOK, "Success", txs)
}

func (h *Handler) Create(c *gin.Context) {
	userID := c.GetString("user_id")
	var req Transaction
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	tx, err := h.service.Create(userID, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create transaction")
		return
	}
	response.Success(c, http.StatusCreated, "Transaction created", tx)
}

func (h *Handler) Update(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	var req Transaction
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	tx, err := h.service.Update(userID, idStr, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update transaction")
		return
	}
	response.Success(c, http.StatusOK, "Transaction updated", tx)
}

func (h *Handler) Delete(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	if err := h.service.Delete(userID, idStr); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete transaction")
		return
	}
	response.Success(c, http.StatusOK, "Transaction deleted", nil)
}
