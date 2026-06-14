package sync

import (
	"time"

	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Service interface {
	Push(userID string, req PushRequest) error
	Pull(userID string, since time.Time) (*PullResponse, error)
}

type service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) Service {
	return &service{db}
}

func (s *service) Push(userID string, req PushRequest) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		// Process Categories Upsert
		for _, cat := range req.Categories {
			cat.UserID = userID // Enforce user ID
			var existing category.Category
			err := tx.Unscoped().Where("id = ? AND user_id = ?", cat.ID, userID).First(&existing).Error
			if err == nil {
				// Last Write Wins
				if existing.UpdatedAt.After(cat.UpdatedAt) {
					continue
				}
			}
			// Upsert
			if err := tx.Clauses(clause.OnConflict{UpdateAll: true}).Create(&cat).Error; err != nil {
				return err
			}
		}

		// Process Categories Delete
		if len(req.DeletedCategoryIDs) > 0 {
			if err := tx.Where("id IN ? AND user_id = ?", req.DeletedCategoryIDs, userID).Delete(&category.Category{}).Error; err != nil {
				return err
			}
		}

		// Process Transactions Upsert
		for _, txn := range req.Transactions {
			txn.UserID = userID // Enforce user ID
			var existing transaction.Transaction
			err := tx.Unscoped().Where("id = ? AND user_id = ?", txn.ID, userID).First(&existing).Error
			if err == nil {
				if existing.UpdatedAt.After(txn.UpdatedAt) {
					continue
				}
			}
			if err := tx.Clauses(clause.OnConflict{UpdateAll: true}).Create(&txn).Error; err != nil {
				return err
			}
		}

		// Process Transactions Delete
		if len(req.DeletedTransactionIDs) > 0 {
			if err := tx.Where("id IN ? AND user_id = ?", req.DeletedTransactionIDs, userID).Delete(&transaction.Transaction{}).Error; err != nil {
				return err
			}
		}

		return nil
	})
}

func (s *service) Pull(userID string, since time.Time) (*PullResponse, error) {
	resp := &PullResponse{}

	// Get Categories
	if err := s.db.Unscoped().Where("user_id = ? AND (updated_at > ? OR deleted_at > ?)", userID, since, since).Find(&resp.Categories).Error; err != nil {
		return nil, err
	}

	// Get Transactions
	if err := s.db.Unscoped().Where("user_id = ? AND (updated_at > ? OR deleted_at > ?)", userID, since, since).Find(&resp.Transactions).Error; err != nil {
		return nil, err
	}

	return resp, nil
}
