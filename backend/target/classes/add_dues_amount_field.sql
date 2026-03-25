-- 添加每日党费金额字段到用户表
ALTER TABLE users ADD COLUMN dues_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '每日党费金额（元）' AFTER email;

-- 为现有用户设置默认党费金额（例如每天1元）
UPDATE users SET dues_amount = 1.00 WHERE dues_amount = 0.00;
