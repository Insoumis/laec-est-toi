package main

import (
	"fmt"
	"framagit.org/laec-is-you/laec-is-you/controllers"
	"framagit.org/laec-is-you/laec-is-you/models"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"log"
	"net/http"
	"os"
)

// Run the HTTP server:
//     go run main.go

func main() {

	// .env and .env.local configuration
	// Go dot env, not Godot Env :)
	_ = godotenv.Load(".env.local")
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Database
	models.ConnectDatabase()

	// HTTP Routing
	router := gin.Default()

	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})

	router.GET("/levels", controllers.IndexLevels)
	router.POST("/levels", controllers.CreateLevel)
	//router.GET("/levels/:id", controllers.ReadLevel)
	//router.PATCH("/levels/:id", controllers.UpdateLevel)
	//router.DELETE("/levels/:id", controllers.DeleteLevel)


	// Listen and serve
	port := os.Getenv("PORT")
	fmt.Printf("Serving on http://localhost:%s\n", port)
	runErr := router.Run()
	if runErr != nil {
		return
	}
}
