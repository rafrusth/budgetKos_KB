package sync

import (
	"net/http"
	"time"

	"budget_kos/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service}
}

func (h *Handler) Push(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		response.Error(c, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req PushRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "Invalid request format")
		return
	}

	if err := h.service.Push(userID, req); err != nil {
		response.Error(c, http.StatusInternalServerError, "Push failed: "+err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Sync push successful", nil)
}

func (h *Handler) Pull(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		response.Error(c, http.StatusUnauthorized, "Unauthorized")
		return
	}

	sinceStr := c.Query("since")
	since := time.Time{}
	if sinceStr != "" {
		t, err := time.Parse(time.RFC3339, sinceStr)
		if err == nil {
			since = t
		}
	}

	resp, err := h.service.Pull(userID, since)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Pull failed: "+err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Sync pull successful", resp)
}
