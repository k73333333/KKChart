package routes

import (
	"github.com/gin-gonic/gin"
	"kkchart-server/controllers"
	"kkchart-server/middleware"
)

// SetupRouter 注册所有的 API 路由并注入相关中间件
func SetupRouter() *gin.Engine {
	r := gin.Default()

	// 添加跨域配置，用于 Web/桌面端 请求
	r.Use(corsMiddleware())

	authCtrl := &controllers.AuthController{}
	aiCtrl := &controllers.AIController{}
	chartCtrl := &controllers.ChartController{}

	api := r.Group("/api/v1")
	{
		// 1. 公共接口（无需鉴权）
		public := api.Group("/")
		{
			public.POST("/register", authCtrl.Register)
			public.POST("/login", authCtrl.Login)
		}

		// 2. 需鉴权与限流的接口
		protected := api.Group("/")
		protected.Use(middleware.JWTAuth(), middleware.RateLimitMiddleware())
		{
			// AI 代理请求，进行严格的频率控制
			protected.POST("/ai/generate", aiCtrl.GenerateChartsProxy)

			// 云端图表同步与增删改查
			protected.POST("/charts", chartCtrl.CreateChart)
			protected.GET("/charts", chartCtrl.GetCharts)
			protected.PUT("/charts/:id", chartCtrl.UpdateChart)
			protected.DELETE("/charts/:id", chartCtrl.DeleteChart)
		}
	}

	return r
}

// corsMiddleware 配置允许跨域访问
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization, Accept")
		
		// 对预检请求直接返回成功
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
