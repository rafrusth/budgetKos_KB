package sync

import (
	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup, handler *Handler) {
	syncGroup := r.Group("/sync")
	{
		syncGroup.POST("/push", handler.Push)
		syncGroup.GET("/pull", handler.Pull)
	}
}
