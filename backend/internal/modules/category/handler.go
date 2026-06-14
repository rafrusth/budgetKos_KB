package category

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
	categories, err := h.service.GetAll(userID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get categories")
		return
	}
	response.Success(c, http.StatusOK, "Success", categories)
}

func (h *Handler) Create(c *gin.Context) {
	userID := c.GetString("user_id")
	var req Category
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	cat, err := h.service.Create(userID, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create category")
		return
	}
	response.Success(c, http.StatusCreated, "Category created", cat)
}

func (h *Handler) Update(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	var req Category
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	cat, err := h.service.Update(userID, idStr, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update category")
		return
	}
	response.Success(c, http.StatusOK, "Category updated", cat)
}

func (h *Handler) Delete(c *gin.Context) {
	userID := c.GetString("user_id")
	idStr := c.Param("id")

	if err := h.service.Delete(userID, idStr); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete category")
		return
	}
	response.Success(c, http.StatusOK, "Category deleted", nil)
}
