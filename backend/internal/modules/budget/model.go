package budget

import (
	"time"
	"budget_kos/backend/internal/modules/category"
)

type Budget struct {
	ID          uint              `json:"id" gorm:"primaryKey"`
	CategoryID  uint              `json:"category_id" gorm:"not null"`
	Category    category.Category `json:"category" gorm:"foreignKey:CategoryID"`
	LimitAmount float64           `json:"limit_amount" gorm:"not null"`
	Month       int               `json:"month" gorm:"not null"`
	Year        int               `json:"year" gorm:"not null"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
}
