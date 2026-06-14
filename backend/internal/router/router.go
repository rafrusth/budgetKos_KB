package router

import (
	"budget_kos/backend/internal/database"
	"budget_kos/backend/internal/middleware"
	"budget_kos/backend/internal/modules/ai"
	"budget_kos/backend/internal/modules/auth"
	"budget_kos/backend/internal/modules/budget"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/sync"
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

		// Public Routes
		auth.RegisterRoutes(api, database.DB)

		// Protected Routes
		protected := api.Group("/")
		protected.Use(middleware.JWTAuth())
		{
			category.RegisterRoutes(protected, database.DB)
			transaction.RegisterRoutes(protected, database.DB)
			budget.RegisterRoutes(protected, database.DB)
			ai.RegisterRoutes(protected, database.DB)
			sync.RegisterRoutes(protected, database.DB)
		}
	}

	return r
}
