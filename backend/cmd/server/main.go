package main

import (
	"log"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/database"
	"budget_kos/backend/internal/router"
	"budget_kos/backend/internal"
)

func main() {
	// Initialize Config
	config.InitConfig()

	// Initialize Database
	database.ConnectDB()
	database.MigrateDB()

	// Initialize DI Container
	container := internal.InitContainer(database.DB)

	// Setup Router
	r := router.SetupRouter(container)

	// Start Server
	port := config.AppConfig.Port
	log.Printf("Starting server on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
