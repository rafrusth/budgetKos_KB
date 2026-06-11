package budget

type Service interface {
	GetAll() ([]Budget, error)
	GetByID(id uint) (*Budget, error)
	Create(req Budget) (*Budget, error)
	Update(id uint, req Budget) (*Budget, error)
	Delete(id uint) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAll() ([]Budget, error) {
	return s.repo.FindAll()
}

func (s *service) GetByID(id uint) (*Budget, error) {
	return s.repo.FindByID(id)
}

func (s *service) Create(req Budget) (*Budget, error) {
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) Update(id uint, req Budget) (*Budget, error) {
	budget, err := s.repo.FindByID(id)
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

func (s *service) Delete(id uint) error {
	return s.repo.Delete(id)
}
