-- 更新学习进度表，添加学习时长字段
ALTER TABLE study_progress ADD COLUMN study_duration INT DEFAULT 0 COMMENT '学习时长（秒）';
