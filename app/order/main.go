package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

type CartItem struct {
	Name	 string `json:"name"`
	Price	 string `json:"price`
	Image	 string `json:"image"`
	Quantity int	`json:"quantity`
}

type Order struct {
	OrderID	 	string 		`json:"order_id"`
	Items	 	[]CartItem  `json:"items"`
	Subtotal 	string		`json:"subtotal"`
	DeliveryFee string		`json:"delivery_fee"`
	Total		string		`json:"total"`
}

var svc *dynamodb.dynamodb

func init() {
	sess, err := session.NewSession(&aws.Config {
		Region: aws.String("ap-northeast-2")
	})

	if err != nil {
		log.Fatalf("Failed to create session: %w", err)
	}

	svc = dynamodb.New(sess)
}

func main() {
	http.HandleFunc("/v1/order", handleOrder)
	port := 8080
	log.Printf("Server starting on port %s...", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}

func handleOrder(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var order Order
	if err := json.NewDecoder(r.Body).Decode(&order); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	orderID := fmt.Sprintf("%d", rand.New(rand.NewSource(time.Now().UnixNano())).Int63())
	order.OrderID = orderID

	item, err := dynamodbattribute.MarshalMap(order)
	if err != nil {
		log.Printf("Failed to marshal order: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	input := &dynamodb.PutItemInput{
		TableName: aws.String("Orders"),
		Item:	   item,
	}

	if _, err := svc.PutItem(input); err != nil {
		log.Printf("Failed to put item in DynamoDB: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	log.Printf("Order %s saved sucessfully!", orderID)
	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "Order %s created successfully", orderID)
}