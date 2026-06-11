package budget

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll() ([]Budget, error)
	FindByID(id uint) (*Budget, error)
	Create(budget *Budget) error
	Update(budget *Budget) error
	Delete(id uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll() ([]Budget, error) {
	var budgets []Budget
	err := r.db.Preload("Category").Find(&budgets).Error
	return budgets, err
}

func (r *repository) FindByID(id uint) (*Budget, error) {
	var budget Budget
	err := r.db.Preload("Category").First(&budget, id).Error
	if err != nil {
		return nil, err
	}
	return &budget, nil
}

func (r *repository) Create(budget *Budget) error {
	return r.db.Create(budget).Error
}

func (r *repository) Update(budget *Budget) error {
	return r.db.Save(budget).Error
}

func (r *repository) Delete(id uint) error {
	return r.db.Delete(&Budget{}, id).Error
}
