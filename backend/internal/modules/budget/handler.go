package budget

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
	budgets, err := h.service.GetAll()
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budgets")
		return
	}
	response.Success(c, http.StatusOK, "Success", budgets)
}

func (h *Handler) Create(c *gin.Context) {
	var req Budget
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	budget, err := h.service.Create(req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create budget")
		return
	}
	response.Success(c, http.StatusCreated, "Budget created", budget)
}

func (h *Handler) Update(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)
	
	var req Budget
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	
	budget, err := h.service.Update(uint(id), req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update budget")
		return
	}
	response.Success(c, http.StatusOK, "Budget updated", budget)
}

func (h *Handler) Delete(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)
	
	if err := h.service.Delete(uint(id)); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete budget")
		return
	}
	response.Success(c, http.StatusOK, "Budget deleted", nil)
}
