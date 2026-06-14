package budget

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
	budgets, err := h.service.GetAll(userID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get budgets")
		return
	}
	response.Success(c, http.StatusOK, "Success", budgets)
}

func (h *Handler) Create(c *gin.Context) {
	userID := c.GetString("user_id")
	var req Budget
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	budget, err := h.service.Create(userID, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create budget")
		return
	}
	response.Success(c, http.StatusCreated, "Budget created", budget)
}

func (h *Handler) Update(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	var req Budget
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	budget, err := h.service.Update(userID, idStr, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update budget")
		return
	}
	response.Success(c, http.StatusOK, "Budget updated", budget)
}

func (h *Handler) Delete(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	if err := h.service.Delete(userID, idStr); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete budget")
		return
	}
	response.Success(c, http.StatusOK, "Budget deleted", nil)
}
