package middleware

import (
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// IP 维度的限流器池
var clients = make(map[string]*rate.Limiter)
var mu sync.Mutex

// 获取特定 IP 的 Limiter，每秒 5 次请求，爆发容量 10 次
func getLimiter(ip string) *rate.Limiter {
	mu.Lock()
	defer mu.Unlock()

	limiter, exists := clients[ip]
	if !exists {
		limiter = rate.NewLimiter(5, 10)
		clients[ip] = limiter
	}
	return limiter
}

// RateLimitMiddleware 全局 API 频率限制中间件
// 防止恶意刷接口，特别保护耗时的 AI 代理接口
func RateLimitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := getLimiter(ip)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "请求过于频繁，请稍后再试",
				"code":  429,
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
