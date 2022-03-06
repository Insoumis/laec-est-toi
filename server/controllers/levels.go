package controllers

import (
	"encoding/json"
	"net/http"

	"framagit.org/laec-is-you/laec-is-you/models"
	"github.com/gin-gonic/gin"
)

type MetadataInput struct {
	Title  string `json:"title" binding:"required"`
}

type CreateLevelInput struct {
	//Phiu  string `json:"phiu" binding:"required"`
	Metadata MetadataInput `json:"metadata" binding:"required"`
	Terrain map[string]int `json:"terrain" binding:"required"`
}

//type UpdateLevelInput struct {
//	Title   string `json:"title"`
//	Authors string `json:"authors"`
//}

// IndexLevels Find all levels
// GET /levels
func IndexLevels(c *gin.Context) {
	var entities []models.Level
	models.DB.Find(&entities)

	c.JSON(http.StatusOK, gin.H{"data": entities})
}

//// GET /books/:id
//// Find a book
//func FindBook(c *gin.Context) {
//	// Get model if exist
//	var book models.Book
//	if err := models.DB.Where("id = ?", c.Param("id")).First(&book).Error; err != nil {
//		c.JSON(http.StatusBadRequest, gin.H{"error": "Record not found!"})
//		return
//	}
//
//	c.JSON(http.StatusOK, gin.H{"data": book})
//}

// CreateLevel creates a new level
// POST /levels
func CreateLevel(c *gin.Context) {
	var input CreateLevelInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	entityJson, marshalErr := json.Marshal(input)
	if nil != marshalErr {
		c.JSON(http.StatusBadRequest, gin.H{"error": marshalErr.Error()})
		return
	}
	entity := models.Level{
		Title: input.Metadata.Title,
		Json: string(entityJson),
	}
	models.DB.Create(&entity)

	c.JSON(http.StatusOK, gin.H{"data": entity})
}

//// PATCH /books/:id
//// Update a book
//func UpdateBook(c *gin.Context) {
//	// Get model if exist
//	var book models.Book
//	if err := models.DB.Where("id = ?", c.Param("id")).First(&book).Error; err != nil {
//		c.JSON(http.StatusBadRequest, gin.H{"error": "Record not found!"})
//		return
//	}
//
//	// Validate input
//	var input UpdateBookInput
//	if err := c.ShouldBindJSON(&input); err != nil {
//		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
//		return
//	}
//
//	models.DB.Model(&book).Updates(input)
//
//	c.JSON(http.StatusOK, gin.H{"data": book})
//}
//
//// DELETE /books/:id
//// Delete a book
//func DeleteBook(c *gin.Context) {
//	// Get model if exist
//	var book models.Book
//	if err := models.DB.Where("id = ?", c.Param("id")).First(&book).Error; err != nil {
//		c.JSON(http.StatusBadRequest, gin.H{"error": "Record not found!"})
//		return
//	}
//
//	models.DB.Delete(&book)
//
//	c.JSON(http.StatusOK, gin.H{"data": true})
//}
