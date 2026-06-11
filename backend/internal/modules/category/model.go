package category

import (
	"time"
)

type Category struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Name      string    `json:"name" gorm:"not null"`
	Icon      string    `json:"icon" gorm:"not null"`
	Color     string    `json:"color" gorm:"not null"`
	Type      string    `json:"type" gorm:"not null"` // "income" or "expense"
	IsDefault bool      `json:"is_default" gorm:"default:false"`
	SortOrder int       `json:"sort_order" gorm:"default:0"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
