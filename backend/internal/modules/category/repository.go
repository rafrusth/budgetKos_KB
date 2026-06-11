package category

import (
	"gorm.io/gorm"
)

type Repository interface {
	FindAll() ([]Category, error)
	FindByID(id uint) (*Category, error)
	Create(category *Category) error
	Update(category *Category) error
	Delete(id uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindAll() ([]Category, error) {
	var categories []Category
	err := r.db.Order("sort_order asc").Find(&categories).Error
	return categories, err
}

func (r *repository) FindByID(id uint) (*Category, error) {
	var category Category
	err := r.db.First(&category, id).Error
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

func (r *repository) Delete(id uint) error {
	return r.db.Delete(&Category{}, id).Error
}
