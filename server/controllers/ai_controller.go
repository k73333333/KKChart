package controllers

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// AIController 处理所有的 AI 代理请求逻辑
// 防止前端直接暴露云端 API Key
type AIController struct{}

// AIProxyRequest 结构用于解析前端发送的数据
type AIProxyRequest struct {
	Prompt string `json:"prompt" binding:"required"`
}

// GenerateChartsProxy 接收前端发送的 Prompt，转发至真实的 AI 服务端点
// 此处模拟接入 OpenAI 兼容的接口
func (a *AIController) GenerateChartsProxy(c *gin.Context) {
	var req AIProxyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数不正确: " + err.Error()})
		return
	}

	apiKey := os.Getenv("AI_API_KEY")
	apiURL := os.Getenv("AI_API_URL")

	if apiKey == "" || apiURL == "" {
		// 回退模拟模式，方便本地测试（如果环境变量没有配置）
		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": "[{\"title\": \"示例饼图\", \"type\": \"pie\", \"option\": {}}]",
		})
		return
	}

	// 构建发送给大模型的请求载荷
	payload := map[string]interface{}{
		"model": "gpt-4", // 或配置的自定义模型
		"messages": []map[string]string{
			{"role": "user", "content": req.Prompt},
		},
		"temperature": 0.3,
	}

	payloadBytes, _ := json.Marshal(payload)
	httpReq, err := http.NewRequest("POST", apiURL, bytes.NewReader(payloadBytes))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "构建 AI 请求失败"})
		return
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+apiKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "AI 服务不可用或超时"})
		return
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	
	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, gin.H{"error": "AI 服务返回错误状态", "details": string(body)})
		return
	}

	// 透传 AI 的 JSON 响应给前端
	var result map[string]interface{}
	json.Unmarshal(body, &result)

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"data": result,
	})
}
