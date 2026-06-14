package category

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll(userID string) ([]Category, error)
	FindByID(userID, id string) (*Category, error)
	Create(category *Category) error
	Update(category *Category) error
	Delete(userID, id string) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll(userID string) ([]Category, error) {
	var categories []Category
	err := r.db.Where("user_id = ?", userID).Order("sort_order asc").Find(&categories).Error
	return categories, err
}

func (r *repository) FindByID(userID, id string) (*Category, error) {
	var category Category
	err := r.db.Where("id = ? AND user_id = ?", id, userID).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *repository) Create(category *Category) error {
	return r.db.Create(category).Error
}

func (r *repository) Update(category *Category) error {
	return r.db.Save(category).Error
}

func (r *repository) Delete(userID, id string) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&Category{}).Error
}
