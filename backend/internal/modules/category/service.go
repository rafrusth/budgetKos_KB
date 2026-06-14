package category

type Service interface {
	GetAll(userID string) ([]Category, error)
	GetByID(userID, id string) (*Category, error)
	Create(userID string, req Category) (*Category, error)
	Update(userID, id string, req Category) (*Category, error)
	Delete(userID, id string) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAll(userID string) ([]Category, error) {
	return s.repo.FindAll(userID)
}

func (s *service) GetByID(userID, id string) (*Category, error) {
	return s.repo.FindByID(userID, id)
}

func (s *service) Create(userID string, req Category) (*Category, error) {
	req.UserID = userID
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) Update(userID, id string, req Category) (*Category, error) {
	cat, err := s.repo.FindByID(userID, id)
	if err != nil {
		return nil, err
	}
	cat.Name = req.Name
	cat.Icon = req.Icon
	cat.Color = req.Color
	cat.Type = req.Type
	cat.IsDefault = req.IsDefault
	cat.SortOrder = req.SortOrder

	err = s.repo.Update(cat)
	return cat, err
}

func (s *service) Delete(userID, id string) error {
	return s.repo.Delete(userID, id)
}
