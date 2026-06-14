package transaction

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll(userID string) ([]Transaction, error)
	FindByID(userID, id string) (*Transaction, error)
	Create(tx *Transaction) error
	Update(tx *Transaction) error
	Delete(userID, id string) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll(userID string) ([]Transaction, error) {
	var txs []Transaction
	err := r.db.Preload("Category").Where("user_id = ?", userID).Order("date desc").Find(&txs).Error
	return txs, err
}

func (r *repository) FindByID(userID, id string) (*Transaction, error) {
	var tx Transaction
	err := r.db.Preload("Category").Where("id = ? AND user_id = ?", id, userID).First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *repository) Create(tx *Transaction) error {
	return r.db.Create(tx).Error
}

func (r *repository) Update(tx *Transaction) error {
	return r.db.Save(tx).Error
}

func (r *repository) Delete(userID, id string) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&Transaction{}).Error
}
