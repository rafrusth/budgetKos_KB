package transaction

type Service interface {
	GetAll(userID string) ([]Transaction, error)
	GetByID(userID, id string) (*Transaction, error)
	Create(userID string, req Transaction) (*Transaction, error)
	Update(userID, id string, req Transaction) (*Transaction, error)
	Delete(userID, id string) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo}
}

func (s *service) GetAll(userID string) ([]Transaction, error) {
	return s.repo.FindAll(userID)
}

func (s *service) GetByID(userID, id string) (*Transaction, error) {
	return s.repo.FindByID(userID, id)
}

func (s *service) Create(userID string, req Transaction) (*Transaction, error) {
	req.UserID = userID
	err := s.repo.Create(&req)
	return &req, err
}

func (s *service) Update(userID, id string, req Transaction) (*Transaction, error) {
	tx, err := s.repo.FindByID(userID, id)
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

func (s *service) Delete(userID, id string) error {
	return s.repo.Delete(userID, id)
}
