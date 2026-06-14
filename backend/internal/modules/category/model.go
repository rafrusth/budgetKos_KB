package category

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Category struct {
	ID         string         `json:"id" gorm:"primaryKey;type:uuid"`
	UserID     string         `json:"user_id" gorm:"index;not null"`
	Name       string         `json:"name"`
	Icon       string         `json:"icon"`
	Color      string         `json:"color"`
	Type       string         `json:"type"`
	IsDefault  bool           `json:"is_default"`
	SortOrder  int            `json:"sort_order"`
	SyncStatus int            `json:"sync_status"`
	IsDeleted  int            `json:"is_deleted"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `json:"-" gorm:"index"`
}

func (c *Category) BeforeCreate(tx *gorm.DB) (err error) {
	if c.ID == "" {
		c.ID = uuid.NewString()
	}
	return
}
