package transaction

import (
	"time"
	"budget_kos/backend/internal/modules/category"
)

type Transaction struct {
	ID         uint              `json:"id" gorm:"primaryKey"`
	Title      string            `json:"title" gorm:"not null"`
	Amount     float64           `json:"amount" gorm:"not null"`
	Type       string            `json:"type" gorm:"not null"` // "income" or "expense"
	CategoryID uint              `json:"category_id"`
	Category   category.Category `json:"category" gorm:"foreignKey:CategoryID"`
	Notes      string            `json:"notes"`
	Date       time.Time         `json:"date" gorm:"not null"`
	CreatedAt  time.Time         `json:"created_at"`
	UpdatedAt  time.Time         `json:"updated_at"`
	IsSynced   bool              `json:"is_synced" gorm:"default:true"`
}
