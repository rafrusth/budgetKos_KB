package ai

import (
	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup, handler *Handler) {
	routes := r.Group("/ai")
	{
		routes.POST("/chat", handler.Chat)
	}
}
