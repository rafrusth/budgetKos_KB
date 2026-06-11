package transaction

import (
	"strconv"
	"net/http"

	"github.com/gin-gonic/gin"
	"budget_kos/backend/pkg/response"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service}
}

func (h *Handler) GetAll(c *gin.Context) {
	txs, err := h.service.GetAll()
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get transactions")
		return
	}
	response.Success(c, http.StatusOK, "Success", txs)
}

func (h *Handler) Create(c *gin.Context) {
	var req Transaction
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	tx, err := h.service.Create(req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create transaction")
		return
	}
	response.Success(c, http.StatusCreated, "Transaction created", tx)
}

func (h *Handler) Update(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)
	
	var req Transaction
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	
	tx, err := h.service.Update(uint(id), req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update transaction")
		return
	}
	response.Success(c, http.StatusOK, "Transaction updated", tx)
}

func (h *Handler) Delete(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)
	
	if err := h.service.Delete(uint(id)); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete transaction")
		return
	}
	response.Success(c, http.StatusOK, "Transaction deleted", nil)
}
