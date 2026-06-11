package main

import (
	"log"
	"time"

	"budget_kos/backend/internal/modules/category"
	"budget_kos/backend/internal/modules/transaction"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func main() {
	db, err := gorm.Open(sqlite.Open("budgetkos.db"), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}

	// Create Categories
	cats := []category.Category{
		{Name: "Uang Saku", Icon: "money", Color: "#4CAF50", Type: "income", IsDefault: true},
		{Name: "Makanan", Icon: "fastfood", Color: "#FF9800", Type: "expense", IsDefault: true},
		{Name: "Transportasi", Icon: "directions_car", Color: "#2196F3", Type: "expense", IsDefault: true},
		{Name: "Kos", Icon: "home", Color: "#9C27B0", Type: "expense", IsDefault: true},
		{Name: "Hiburan", Icon: "movie", Color: "#E91E63", Type: "expense", IsDefault: true},
	}

	for i, c := range cats {
		var existing category.Category
		if err := db.Where("name = ?", c.Name).First(&existing).Error; err != nil {
			db.Create(&cats[i])
		} else {
			cats[i] = existing
		}
	}

	// Create Transactions
	txs := []transaction.Transaction{
		{Title: "Transfer Orang Tua", Amount: 2000000, Type: "income", CategoryID: cats[0].ID, Date: time.Now().AddDate(0, 0, -10)},
		{Title: "Bayar Kos Bulan Ini", Amount: 800000, Type: "expense", CategoryID: cats[3].ID, Date: time.Now().AddDate(0, 0, -9)},
		{Title: "Beli Nasi Padang", Amount: 25000, Type: "expense", CategoryID: cats[1].ID, Date: time.Now().AddDate(0, 0, -8)},
		{Title: "Isi Bensin Motor", Amount: 30000, Type: "expense", CategoryID: cats[2].ID, Date: time.Now().AddDate(0, 0, -7)},
		{Title: "Nonton Bioskop", Amount: 60000, Type: "expense", CategoryID: cats[4].ID, Date: time.Now().AddDate(0, 0, -6)},
		{Title: "Beli Kopi Kenangan", Amount: 20000, Type: "expense", CategoryID: cats[1].ID, Date: time.Now().AddDate(0, 0, -5)},
		{Title: "Token Listrik", Amount: 50000, Type: "expense", CategoryID: cats[3].ID, Date: time.Now().AddDate(0, 0, -4)},
		{Title: "Beli Indomie", Amount: 15000, Type: "expense", CategoryID: cats[1].ID, Date: time.Now().AddDate(0, 0, -3)},
		{Title: "Service Motor", Amount: 100000, Type: "expense", CategoryID: cats[2].ID, Date: time.Now().AddDate(0, 0, -2)},
		{Title: "Makan Pecel Lele", Amount: 20000, Type: "expense", CategoryID: cats[1].ID, Date: time.Now().AddDate(0, 0, -1)},
	}

	for _, tx := range txs {
		db.Create(&tx)
	}

	log.Println("Dummy data successfully injected!")
}
