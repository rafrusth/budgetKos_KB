package config

import (
	"log"

	"github.com/spf13/viper"
)

type Config struct {
	Port         string `mapstructure:"PORT"`
	DBFile       string `mapstructure:"DB_FILE"`
	GinMode      string `mapstructure:"GIN_MODE"`
	GeminiAPIKey string `mapstructure:"GEMINI_API_KEY"`
}

var AppConfig *Config

func InitConfig() {
	viper.SetConfigFile(".env")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		log.Println("Warning: No .env file found or error reading it, using environment variables")
	}

	AppConfig = &Config{}
	err := viper.Unmarshal(AppConfig)
	if err != nil {
		log.Fatalf("Unable to decode into struct, %v", err)
	}

	// Set defaults
	if AppConfig.Port == "" {
		AppConfig.Port = "8080"
	}
	if AppConfig.DBFile == "" {
		AppConfig.DBFile = "budgetkos.db"
	}
}
