package main

import (
	"context"
	"fmt"
	"golang-containerization/scripts/connection"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

type Status struct {
	Health  bool   `json:"health"`
	Message string `json:"message"`
}

func main() {
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	router.GET("/", func(c *gin.Context) {
		conn := connection.Connect()
		defer conn.Close()

		errMysql := conn.Ping()
		mysql := Status{
			Health:  errMysql == nil,
			Message: "MySQL is connected",
		}

		if errMysql != nil {
			mysql.Message = errMysql.Error()
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Hello World!",
			"health": gin.H{
				"mysql": mysql,
			},
		})
	})

	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
		})
	})

	port := os.Getenv("PORT")
	srv := &http.Server{
		Addr:           fmt.Sprintf(":%s", port),
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}

	go func() {
		log.Printf("server starting on port :%s\n", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	err := handleShutdown(srv)
	if err != nil {
		panic(err)
	}
}

func handleShutdown(srv *http.Server) error {
	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var err error
	if err = srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("Server exiting")
	return err
}
