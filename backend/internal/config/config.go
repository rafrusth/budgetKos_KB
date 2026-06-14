package config

import (
	"log"

	"github.com/spf13/viper"
)

type Config struct {
	Port         string `mapstructure:"PORT"`
	DatabaseURL  string `mapstructure:"DATABASE_URL"`
	GinMode      string `mapstructure:"GIN_MODE"`
	GroqAPIKey   string `mapstructure:"GROQ_API_KEY"`
	JWTSecret    string `mapstructure:"JWT_SECRET"`
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
	if AppConfig.DatabaseURL == "" {
		AppConfig.DatabaseURL = "host=localhost user=postgres password=postgres dbname=budgetkos port=5432 sslmode=disable TimeZone=Asia/Jakarta"
	}
	if AppConfig.JWTSecret == "" {
		AppConfig.JWTSecret = "super-secret-key-for-development-only"
	}
}
