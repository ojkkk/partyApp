-- 更新现有的活动数据，确保created_by字段有值
USE partyapp;

-- 更新已有的活动，将created_by设置为admin用户（id='1'）
UPDATE activities SET created_by = '1' WHERE created_by IS NULL;

-- 插入一些测试活动数据（如果需要）
INSERT INTO activities (id, title, content, start_time, end_time, location, organizer, image_url, status, participant_count, max_participants, created_by) VALUES
('act1', '党员学习会议', '开展党员学习教育活动，学习最新政策精神', '2026-03-15 09:00:00', '2026-03-15 11:00:00', '党委会议室', '党委办公室', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20meeting%20room&image_size=landscape_16_9', 'upcoming', 0, 50, '1'),
('act2', '志愿服务活动', '组织党员开展社区志愿服务活动', '2026-03-20 14:00:00', '2026-03-20 17:00:00', '阳光社区', '第一党支部', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=volunteer%20activity&image_size=landscape_16_9', 'upcoming', 0, 30, '2')
ON DUPLICATE KEY UPDATE title=title;

-- 查看更新后的数据
SELECT id, title, created_by, created_at FROM activities;
