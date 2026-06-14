package transaction

import (
	"budget_kos/backend/internal/modules/category"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Transaction struct {
	ID         string            `json:"id" gorm:"primaryKey;type:uuid"`
	UserID     string            `json:"user_id" gorm:"index;not null"`
	Title      string            `json:"title" gorm:"not null"`
	Amount     float64           `json:"amount" gorm:"not null"`
	Type       string            `json:"type" gorm:"not null;index"` // "income" or "expense"
	CategoryID string            `json:"category_id" gorm:"index;type:uuid"`
	Category   category.Category `json:"category" gorm:"foreignKey:CategoryID"`
	Notes      string            `json:"notes"`
	Date       time.Time         `json:"date" gorm:"not null;index"`
	CreatedAt  time.Time         `json:"created_at"`
	UpdatedAt  time.Time         `json:"updated_at"`
	DeletedAt  gorm.DeletedAt    `json:"deleted_at" gorm:"index"`
	IsSynced   bool              `json:"is_synced" gorm:"default:true"`
}

func (t *Transaction) BeforeCreate(tx *gorm.DB) (err error) {
	if t.ID == "" {
		t.ID = uuid.NewString()
	}
	return
}
