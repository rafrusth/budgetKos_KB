package budget

import (
	"budget_kos/backend/internal/modules/category"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Budget struct {
	ID          string            `json:"id" gorm:"primaryKey;type:uuid"`
	UserID      string            `json:"user_id" gorm:"index;not null"`
	CategoryID  string            `json:"category_id" gorm:"not null;type:uuid"`
	Category    category.Category `json:"category" gorm:"foreignKey:CategoryID"`
	LimitAmount float64           `json:"limit_amount" gorm:"not null"`
	Month       int               `json:"month" gorm:"not null"`
	Year        int               `json:"year" gorm:"not null"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
	DeletedAt   gorm.DeletedAt    `json:"deleted_at" gorm:"index"`
}

func (b *Budget) BeforeCreate(tx *gorm.DB) (err error) {
	if b.ID == "" {
		b.ID = uuid.NewString()
	}
	return
}
