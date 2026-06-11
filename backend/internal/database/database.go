package database

import (
	"log"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/modules/budget"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {
	var err error
	
	dbFile := config.AppConfig.DBFile
	if dbFile == "" {
		dbFile = "budgetkos.db"
	}

	DB, err = gorm.Open(sqlite.Open(dbFile), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Database connection established")
}

func MigrateDB() {
	err := DB.AutoMigrate(
		&category.Category{},
		&transaction.Transaction{},
		&budget.Budget{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	log.Println("Database migration completed")
}
