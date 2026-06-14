package sync

import (
	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
)

type PushRequest struct {
	Transactions          []transaction.Transaction `json:"transactions"`
	Categories            []category.Category       `json:"categories"`
	DeletedTransactionIDs []string                  `json:"deleted_transaction_ids"`
	DeletedCategoryIDs    []string                  `json:"deleted_category_ids"`
}

type PullResponse struct {
	Transactions []transaction.Transaction `json:"transactions"`
	Categories   []category.Category       `json:"categories"`
}
