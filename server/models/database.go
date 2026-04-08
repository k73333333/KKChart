package models

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

// InitDB 初始化数据库连接
// 使用 SQLite 作为存储，方便部署
func InitDB() {
	var err error
	DB, err = gorm.Open(sqlite.Open("kkchart.db"), &gorm.Config{})
	if err != nil {
		log.Fatalf("无法连接到数据库: %v", err)
	}

	// 自动迁移模型结构
	err = DB.AutoMigrate(&User{}, &Chart{})
	if err != nil {
		log.Fatalf("数据库迁移失败: %v", err)
	}
	
	log.Println("数据库初始化成功，模型迁移完成")
}
