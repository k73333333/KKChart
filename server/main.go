package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"kkchart-server/models"
	"kkchart-server/routes"
)

// @title KKChart API
// @version 1.0
// @description KKChart 后端接口文档，支持 AI 图表生成、云端数据同步、注册登录等核心功能。
// @host localhost:8080
// @BasePath /api/v1
func main() {
	// 加载本地环境变量，例如 AI_API_KEY
	if err := godotenv.Load(); err != nil {
		log.Println("警告：未找到 .env 文件，将使用系统环境变量")
	}

	// 1. 初始化 SQLite 数据库及数据模型迁移
	models.InitDB()

	// 2. 配置并注册所有 Gin 路由
	r := routes.SetupRouter()

	// 3. 启动 HTTP 监听，默认 8080 端口
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("KKChart 后端服务启动于端口 :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("服务启动失败: %v", err)
	}
}
