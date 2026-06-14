package budget

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll(userID string) ([]Budget, error)
	FindByID(userID, id string) (*Budget, error)
	Create(budget *Budget) error
	Update(budget *Budget) error
	Delete(userID, id string) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll(userID string) ([]Budget, error) {
	var budgets []Budget
	err := r.db.Preload("Category").Where("user_id = ?", userID).Find(&budgets).Error
	return budgets, err
}

func (r *repository) FindByID(userID, id string) (*Budget, error) {
	var budget Budget
	err := r.db.Preload("Category").Where("id = ? AND user_id = ?", id, userID).First(&budget).Error
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

func (r *repository) Delete(userID, id string) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&Budget{}).Error
}
