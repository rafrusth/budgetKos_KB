package internal

import (
	"budget_kos/backend/internal/modules/ai"
	"budget_kos/backend/internal/modules/auth"
	"budget_kos/backend/internal/modules/budget"
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/sync"
	"budget_kos/backend/internal/modules/transaction"
	"gorm.io/gorm"
)

type AppContainer struct {
	AuthHandler        *auth.Handler
	CategoryHandler    *category.Handler
	TransactionHandler *transaction.Handler
	BudgetHandler      *budget.Handler
	AIHandler          *ai.Handler
	SyncHandler        *sync.Handler
}

func InitContainer(db *gorm.DB) *AppContainer {
	// 1. Repositories
	authRepo := auth.NewRepository(db)
	catRepo := category.NewRepository(db)
	txRepo := transaction.NewRepository(db)
	budgetRepo := budget.NewRepository(db)

	// 2. Services
	authService := auth.NewService(authRepo)
	catService := category.NewService(catRepo)
	txService := transaction.NewService(txRepo)
	budgetService := budget.NewService(budgetRepo)
	aiService := ai.NewService(txService, catService)
	syncService := sync.NewService(db)

	// 3. Handlers
	authHandler := auth.NewHandler(authService)
	catHandler := category.NewHandler(catService)
	txHandler := transaction.NewHandler(txService)
	budgetHandler := budget.NewHandler(budgetService)
	aiHandler := ai.NewHandler(aiService)
	syncHandler := sync.NewHandler(syncService)

	return &AppContainer{
		AuthHandler:        authHandler,
		CategoryHandler:    catHandler,
		TransactionHandler: txHandler,
		BudgetHandler:      budgetHandler,
		AIHandler:          aiHandler,
		SyncHandler:        syncHandler,
	}
}
