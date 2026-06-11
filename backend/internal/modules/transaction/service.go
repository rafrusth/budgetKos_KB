package transaction

type Service interface {
	GetAll() ([]Transaction, error)
	GetByID(id uint) (*Transaction, error)
	Create(req Transaction) (*Transaction, error)
	Update(id uint, req Transaction) (*Transaction, error)
	Delete(id uint) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAll() ([]Transaction, error) {
	return s.repo.FindAll()
}

func (s *service) GetByID(id uint) (*Transaction, error) {
	return s.repo.FindByID(id)
}

func (s *service) Create(req Transaction) (*Transaction, error) {
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) Update(id uint, req Transaction) (*Transaction, error) {
	tx, err := s.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	tx.Title = req.Title
	tx.Amount = req.Amount
	tx.Type = req.Type
	tx.CategoryID = req.CategoryID
	tx.Notes = req.Notes
	tx.Date = req.Date
	
	err = s.repo.Update(tx)
	return tx, err
}

func (s *service) Delete(id uint) error {
	return s.repo.Delete(id)
}
