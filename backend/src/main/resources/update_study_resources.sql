-- 更新学习资源表的类型枚举值
ALTER TABLE study_resources MODIFY COLUMN type ENUM('党史学习', '专题学习') NOT NULL COMMENT '类型';

-- 更新现有数据，将其他类型转换为专题学习
UPDATE study_resources SET type = '专题学习' WHERE type NOT IN ('党史学习', '专题学习');
