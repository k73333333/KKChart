package models

import (
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// User 用户模型
// 存储用户的基本信息和认证凭证
type User struct {
	gorm.Model
	Username string `gorm:"uniqueIndex;not null" json:"username"` // 用户名，唯一
	Password string `gorm:"not null" json:"-"`                    // 密码，JSON 序列化时忽略，防止泄露
	Email    string `gorm:"uniqueIndex;not null" json:"email"`    // 邮箱地址
	Charts   []Chart `gorm:"foreignKey:UserID" json:"charts"`     // 关联的图表数据
}

// SetPassword 将明文密码加密后保存
func (u *User) SetPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.Password = string(hashedPassword)
	return nil
}

// CheckPassword 验证密码是否正确
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}
