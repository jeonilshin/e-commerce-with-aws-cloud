package main

import (
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
	"time"

    "github.com/dgrijalva/jwt-go"
    _ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

var jwtKey = []byte("amVvbmlsc2hpbg==")

type Credentials struct {
    Username string `json:"username"`
    Password string `json:"password"`
}

type Claims struct {
    Username string `json:"username"`
    jwt.StandardClaims
}

func main() {
    dbUser := os.Getenv("DB_USER")
    dbPassword := os.Getenv("DB_PASSWORD")
    dbHost := os.Getenv("DB_HOST")
    dbPort := os.Getenv("DB_PORT")
    dbName := os.Getenv("DB_NAME")

    dbConnectionString := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPassword, dbHost, dbPort, dbName)

    var err error
    db, err = sql.Open("mysql", dbConnectionString)
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()

    http.HandleFunc("/v1/login", login)
    http.HandleFunc("/v1/register", register)
    http.HandleFunc("/v1/protected", protectedEndpoint)
    http.HandleFunc("/healthcheck", healthCheck)

    fmt.Println("Server started on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func register(w http.ResponseWriter, r *http.Request) {
    var creds Credentials
    err := json.NewDecoder(r.Body).Decode(&creds)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        return
    }

    var exists bool
    query := "SELECT EXISTS(SELECT 1 FROM users WHERE username=?)"
    err = db.QueryRow(query, creds.Username).Scan(&exists)
    if err != nil {
        http.Error(w, "Database error", http.StatusInternalServerError)
        return
    }

    if exists {
        http.Error(w, "Username already exists", http.StatusConflict)
        return
    }

    _, err = db.Exec("INSERT INTO users (username, password) VALUES (?, ?)", creds.Username, creds.Password)
    if err != nil {
        http.Error(w, "Failed to register user", http.StatusInternalServerError)
        return
    }

    // Respond with a success status
    w.WriteHeader(http.StatusCreated)
    w.Write([]byte(`{"message": "Registration successful!"}`))
}

func login(w http.ResponseWriter, r *http.Request) {
    var creds Credentials
    err := json.NewDecoder(r.Body).Decode(&creds)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        return
    }

    var storedPassword string
    err = db.QueryRow("SELECT password FROM users WHERE username=?", creds.Username).Scan(&storedPassword)
    if err != nil {
        if err == sql.ErrNoRows {
            w.WriteHeader(http.StatusUnauthorized)
            return
        }
        w.WriteHeader(http.StatusInternalServerError)
        return
    }

    if storedPassword != creds.Password {
        w.WriteHeader(http.StatusUnauthorized)
        return
    }

    expirationTime := time.Now().Add(24 * time.Hour)
    claims := &Claims{
        Username: creds.Username,
        StandardClaims: jwt.StandardClaims{
            ExpiresAt: expirationTime.Unix(),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString(jwtKey)
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        return
    }

    http.SetCookie(w, &http.Cookie{
        Name:    "token",
        Value:   tokenString,
        Expires: expirationTime,
        Path:    "/",
    })
}

func protectedEndpoint(w http.ResponseWriter, r *http.Request) {
    c, err := r.Cookie("token")
    if err != nil {
        if err == http.ErrNoCookie {
            w.WriteHeader(http.StatusUnauthorized)
            return
        }
        w.WriteHeader(http.StatusBadRequest)
        return
    }

    tokenStr := c.Value
    claims := &Claims{}

    tkn, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
        return jwtKey, nil
    })

    if err != nil {
        if err == jwt.ErrSignatureInvalid {
            w.WriteHeader(http.StatusUnauthorized)
            return
        }
        w.WriteHeader(http.StatusBadRequest)
        return
    }

    if !tkn.Valid {
        w.WriteHeader(http.StatusUnauthorized)
        return
    }

    w.Write([]byte(fmt.Sprintf("Hello, %s", claims.Username)))
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
    err := db.Ping()
    if err != nil {
        http.Error(w, "Database connection is not healthy", http.StatusInternalServerError)
        return
    }

    response := map[string]string{"status": "ok", "message": "Server is healthy"}
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
