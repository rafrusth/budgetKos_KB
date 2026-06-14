package sync

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB) {
	service := NewService(db)
	handler := NewHandler(service)

	syncGroup := r.Group("/sync")
	{
		syncGroup.POST("/push", handler.Push)
		syncGroup.GET("/pull", handler.Pull)
	}
}
