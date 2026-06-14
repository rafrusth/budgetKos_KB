package budget

type Service interface {
	GetAll(userID string) ([]Budget, error)
	GetByID(userID, id string) (*Budget, error)
	Create(userID string, req Budget) (*Budget, error)
	Update(userID, id string, req Budget) (*Budget, error)
	Delete(userID, id string) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAll(userID string) ([]Budget, error) {
	return s.repo.FindAll(userID)
}

func (s *service) GetByID(userID, id string) (*Budget, error) {
	return s.repo.FindByID(userID, id)
}

func (s *service) Create(userID string, req Budget) (*Budget, error) {
	req.UserID = userID
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) Update(userID, id string, req Budget) (*Budget, error) {
	budget, err := s.repo.FindByID(userID, id)
	if err != nil {
		return nil, err
	}
	budget.CategoryID = req.CategoryID
	budget.LimitAmount = req.LimitAmount
	budget.Month = req.Month
	budget.Year = req.Year

	err = s.repo.Update(budget)
	return budget, err
}

func (s *service) Delete(userID, id string) error {
	return s.repo.Delete(userID, id)
}
