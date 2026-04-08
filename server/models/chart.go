package models

import "gorm.io/gorm"

// Chart 图表数据模型
// 保存用户通过 AI 生成的 ECharts 配置和相关元数据
type Chart struct {
	gorm.Model
	UserID      uint   `gorm:"not null" json:"user_id"`         // 关联的用户ID
	Title       string `gorm:"not null" json:"title"`           // 图表标题，方便检索
	ChartType   string `gorm:"not null" json:"chart_type"`      // 图表类型 (如 bar, pie, line)
	OptionJSON  string `gorm:"type:text;not null" json:"option"`// 核心数据，完整的 ECharts JSON 字符串
	RawData     string `gorm:"type:text" json:"raw_data"`       // 原始输入数据，方便溯源
	Description string `gorm:"type:text" json:"description"`    // AI 给出的图表分析或描述
	IsPublic    bool   `gorm:"default:false" json:"is_public"`  // 是否公开分享（预留功能）
}
