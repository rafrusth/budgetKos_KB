package database

import (
	"log"

	"budget_kos/backend/internal/config"
	"budget_kos/backend/internal/modules/budget"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"budget_kos/backend/internal/modules/user"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {
	var err error

	dsn := config.AppConfig.DatabaseURL

	DB, err = gorm.Open(postgres.New(postgres.Config{
		DSN:                  dsn,
		PreferSimpleProtocol: true,
	}), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Database connection established")
}

func MigrateDB() {
	err := DB.AutoMigrate(
		&user.User{},
		&category.Category{},
		&transaction.Transaction{},
		&budget.Budget{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	log.Println("Database migration completed")
}
