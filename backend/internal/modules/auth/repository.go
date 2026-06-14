package auth

import (
	"budget_kos/backend/internal/modules/user"
	"gorm.io/gorm"
)

type Repository interface {
	FindByEmail(email string) (*user.User, error)
	Create(u *user.User) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db}
}

func (r *repository) FindByEmail(email string) (*user.User, error) {
	var u user.User
	err := r.db.Where("email = ?", email).First(&u).Error
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *repository) Create(u *user.User) error {
	return r.db.Create(u).Error
}
