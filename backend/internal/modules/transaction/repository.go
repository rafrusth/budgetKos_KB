package transaction

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll() ([]Transaction, error)
	FindByID(id uint) (*Transaction, error)
	Create(tx *Transaction) error
	Update(tx *Transaction) error
	Delete(id uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll() ([]Transaction, error) {
	var txs []Transaction
	err := r.db.Preload("Category").Order("date desc").Find(&txs).Error
	return txs, err
}

func (r *repository) FindByID(id uint) (*Transaction, error) {
	var tx Transaction
	err := r.db.Preload("Category").First(&tx, id).Error
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

func (r *repository) Delete(id uint) error {
	return r.db.Delete(&Transaction{}, id).Error
}
