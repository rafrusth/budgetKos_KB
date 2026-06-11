package category

type Service interface {
	GetAllCategories() ([]Category, error)
	GetCategoryByID(id uint) (*Category, error)
	CreateCategory(req Category) (*Category, error)
	UpdateCategory(id uint, req Category) (*Category, error)
	DeleteCategory(id uint) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAllCategories() ([]Category, error) {
	return s.repo.FindAll()
}

func (s *service) GetCategoryByID(id uint) (*Category, error) {
	return s.repo.FindByID(id)
}

func (s *service) CreateCategory(req Category) (*Category, error) {
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) UpdateCategory(id uint, req Category) (*Category, error) {
	cat, err := s.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	cat.Name = req.Name
	cat.Icon = req.Icon
	cat.Color = req.Color
	cat.Type = req.Type
	err = s.repo.Update(cat)
	return cat, err
}

func (s *service) DeleteCategory(id uint) error {
	return s.repo.Delete(id)
}
