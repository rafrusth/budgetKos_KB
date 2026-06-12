package ai

import (
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RegisterRoutes(api *gin.RouterGroup, db *gorm.DB) {
	txRepo := transaction.NewRepository(db)
	txService := transaction.NewService(txRepo)

	catRepo := category.NewRepository(db)
	catService := category.NewService(catRepo)

	service := NewService(txService, catService)
	handler := NewHandler(service)

	routes := api.Group("/ai")
	{
		routes.POST("/chat", handler.Chat)
	}
}
