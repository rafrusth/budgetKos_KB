package category

import (
	"net/http"
	"strconv"

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
	categories, err := h.service.GetAllCategories()
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to get categories")
		return
	}
	response.Success(c, http.StatusOK, "Success", categories)
}

func (h *Handler) Create(c *gin.Context) {
	var req Category
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}
	cat, err := h.service.CreateCategory(req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to create category")
		return
	}
	response.Success(c, http.StatusCreated, "Category created", cat)
}

func (h *Handler) Update(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)

	var req Category
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request")
		return
	}

	cat, err := h.service.UpdateCategory(uint(id), req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update category")
		return
	}
	response.Success(c, http.StatusOK, "Category updated", cat)
}

func (h *Handler) Delete(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)

	if err := h.service.DeleteCategory(uint(id)); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to delete category")
		return
	}
	response.Success(c, http.StatusOK, "Category deleted", nil)
}
