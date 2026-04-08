package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"kkchart-server/models"
)

// ChartController 管理图表数据在服务端的增删改查
type ChartController struct{}

// CreateChart 保存一个从前端生成的图表至云端
func (ctrl *ChartController) CreateChart(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var input struct {
		Title       string `json:"title" binding:"required"`
		ChartType   string `json:"chart_type" binding:"required"`
		OptionJSON  string `json:"option" binding:"required"`
		RawData     string `json:"raw_data"`
		Description string `json:"description"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	chart := models.Chart{
		UserID:      userID.(uint),
		Title:       input.Title,
		ChartType:   input.ChartType,
		OptionJSON:  input.OptionJSON,
		RawData:     input.RawData,
		Description: input.Description,
	}

	if result := models.DB.Create(&chart); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存图表失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "图表保存成功",
		"data":    chart,
	})
}

// GetCharts 分页获取当前用户的图表列表
func (ctrl *ChartController) GetCharts(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var charts []models.Chart
	if result := models.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&charts); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取列表失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"data": charts,
	})
}

// DeleteChart 根据图表 ID 删除一条记录，仅能删除属于自己的
func (ctrl *ChartController) DeleteChart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	chartID := c.Param("id")

	var chart models.Chart
	if result := models.DB.Where("id = ? AND user_id = ?", chartID, userID).First(&chart); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "图表不存在或无权删除"})
		return
	}

	if result := models.DB.Delete(&chart); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "删除成功"})
}

// UpdateChart 更新图表配置
func (ctrl *ChartController) UpdateChart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	chartID := c.Param("id")

	var chart models.Chart
	if result := models.DB.Where("id = ? AND user_id = ?", chartID, userID).First(&chart); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "图表不存在或无权更新"})
		return
	}

	var input struct {
		Title      string `json:"title"`
		OptionJSON string `json:"option"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 仅更新非空字段
	if input.Title != "" {
		chart.Title = input.Title
	}
	if input.OptionJSON != "" {
		chart.OptionJSON = input.OptionJSON
	}

	if result := models.DB.Save(&chart); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "更新成功", "data": chart})
}
