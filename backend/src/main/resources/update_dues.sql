-- 1. 修复：修改为DATETIME类型，支持CURRENT_TIMESTAMP默认值
ALTER TABLE users ADD COLUMN registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册日期' AFTER join_date;

-- 2. 创建党费缴纳表（无错误，保留）
CREATE TABLE IF NOT EXISTS dues_payments (
  id VARCHAR(36) PRIMARY KEY COMMENT '缴费ID',
  user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
  payment_month DATE NOT NULL COMMENT '缴费月份',
  amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '缴费金额',
  payment_method ENUM('online', 'offline') DEFAULT NULL COMMENT '缴费方式',
  payment_status ENUM('pending', 'paid', 'overdue') DEFAULT 'pending' COMMENT '缴费状态',
  payment_date TIMESTAMP NULL COMMENT '缴费时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY uk_user_month (user_id, payment_month),
  INDEX idx_user_id (user_id),
  INDEX idx_payment_month (payment_month),
  INDEX idx_payment_status (payment_status),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='党费缴纳表';

-- 3. 更新现有用户注册日期（无错误，保留）
UPDATE users SET registration_date = CURRENT_DATE WHERE registration_date IS NULL;

-- 4. 生成当月党费记录（无错误，保留）
INSERT INTO dues_payments (id, user_id, payment_month, amount, payment_status)
SELECT
  UUID() as id,
  id as user_id,
  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01') as payment_month,
  10.00 as amount, -- 默认每月10元
  'overdue' as payment_status
FROM users
ON DUPLICATE KEY UPDATE payment_status = 'overdue';