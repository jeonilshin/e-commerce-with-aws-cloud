package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	
	_ "github.com/go-sql-driver/mysql"
)

type User struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

var db *sql.DB
var dbErr error

var mutex = &sync.Mutex{}

func main() {
	db, dbErr = sql.Open("mysql", os.Getenv("DB_CONNECTION_STRING"))
	if dbErr != nil {
		log.Fatalf("Error connecting to the database: %v", dbErr)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Could not ping DB: %v", err)
	}

	http.HandleFunc("/v1/form", handleForm)

	fmt.Println("Server started at :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func handleForm(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is supported", http.StatusMethodNotAllowed)
		return
	}

	err := r.ParseForm()
	if err != nil {
		http.Error(w, "Error parsing form", http.StatusBadRequest)
		return
	}

	action := r.URL.Query().Get("action")
	username := r.FormValue("username")
	password := r.FormValue("password")

	if username == "" || password == "" {
		http.Error(w, "Username and password are required", http.StatusBadRequest)
		return
	}

	mutex.Lock()
	defer mutex.Unlock()

	switch action {
	case "login":
		handleLogin(w, username, password)
	case "register":
		handleRegister(w, username, password)
	default:
		http.Error(w, "Invalid action", http.StatusBadRequest)
	}
}

func handleLogin(w http.ResponseWriter, username, password string) {
	var storedPassword string

	query := "SELECT password FROM users WHERE username = ?"
	err := db.QueryRow(query, username).Scan(&storedPassword)

	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Invalid username or password", http.StatusUnauthorized)
			return
		}
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if storedPassword != password {
		http.Error(w, "Invalid username or password", http.StatusUnauthorized)
		return
	}

	response := map[string]string{"message": "Login successful!"}
	json.NewEncoder(w).Encode(response)
}

func handleRegister(w http.ResponseWriter, username, password string) {
	var exists bool

	query := "SELECT EXISTS(SELECT 1 FROM users WHERE username = ?)"
	err := db.QueryRow(query, username).Scan(&exists)

	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if exists {
		http.Error(w, "Username already exists", http.StatusConflict)
		return
	}

	insertQuery := "INSERT INTO users (username, password) VALUES (?, ?)"
	_, err = db.Exec(insertQuery, username, password)

	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	response := map[string]string{"message": "Registration successful!"}
	json.NewEncoder(w).Encode(response)
}