package router

import (
	"budget_kos/backend/internal/database"
	"budget_kos/backend/internal/middleware"
	"budget_kos/backend/internal/modules/ai"
	"budget_kos/backend/internal/modules/budget"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	r.Use(middleware.CORSMiddleware())

	api := r.Group("/api/v1")
	{
		api.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "pong"})
		})

		category.RegisterRoutes(api, database.DB)
		transaction.RegisterRoutes(api, database.DB)
		budget.RegisterRoutes(api, database.DB)
		ai.RegisterRoutes(api, database.DB)
	}

	return r
}
