-- 完整测试数据
-- 密码使用BCrypt加密，所有用户密码均为：123456

-- 清空现有数据
DELETE FROM messages;
DELETE FROM activity_registrations;
DELETE FROM activities;
DELETE FROM study_progress;
DELETE FROM study_resources;
DELETE FROM policy_favorites;
DELETE FROM policies;
DELETE FROM dues_payments;
DELETE FROM branch_application_messages;
DELETE FROM branch_applications;
DELETE FROM branches;
DELETE FROM users;

-- 用户数据（密码已加密）
INSERT INTO users (id, username, password, name, role, party_id, branch, join_date, registration_date, phone, email, avatar) VALUES
('1', 'admin', '$2a$10$eWxp7YAAGAbod2Ot8zVZV.3RtDvdJjnsPZrzj2P6yHHNknfNtgZvW', '系统管理员', 'admin', 'P001', '党委', '2020-01-01', '2020-01-01', '13800138001', 'admin@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20male%20party%20member&image_size=square'),
('2', 'branch_admin1', '$2a$10$msH5RxcXOJ1S.b9P8ilh/uGxzwYKenQe1KX96eKJvSRG3erE3XUPC', '第一支部管理员', 'branch_admin', 'P002', '第一党支部', '2020-02-01', '2020-02-01', '13800138002', 'branch1@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20female%20party%20member&image_size=square'),
('3', 'branch_admin2', '$2a$10$msH5RxcXOJ1S.b9P8ilh/uGxzwYKenQe1KX96eKJvSRG3erE3XUPC', '第二支部管理员', 'branch_admin', 'P003', '第二党支部', '2020-03-01', '2020-03-01', '13800138003', 'branch2@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20male%20party%20member%20glasses&image_size=square'),
('4', 'member1', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '张三', 'member', 'P004', '第一党支部', '2020-04-01', '2020-04-01', '13800138004', 'member1@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20male%20young%20party%20member&image_size=square'),
('5', 'member2', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '李四', 'member', 'P005', '第一党支部', '2020-05-01', '2020-05-01', '13800138005', 'member2@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20female%20young%20party%20member&image_size=square'),
('6', 'member3', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '王五', 'member', 'P006', '第二党支部', '2020-06-01', '2020-06-01', '13800138006', 'member3@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20male%20middle%20age%20party%20member&image_size=square'),
('7', 'member4', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '赵六', 'member', 'P007', '第二党支部', '2020-07-01', '2020-07-01', '13800138007', 'member4@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20female%20middle%20age%20party%20member&image_size=square'),
('8', 'member5', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '钱七', 'member', 'P008', '第一党支部', '2020-08-01', '2020-08-01', '13800138008', 'member5@example.com', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20asian%20male%20senior%20party%20member&image_size=square');

-- 支部数据
INSERT INTO branches (id, name, admin_id) VALUES
('b1', '第一党支部', '2'),
('b2', '第二党支部', '3');

-- 支部申请数据
INSERT INTO branch_applications (id, user_id, branch_id, status, apply_date, approve_date) VALUES
('ba1', '4', 'b1', 'approved', '2026-01-01', '2026-01-02'),
('ba2', '5', 'b1', 'approved', '2026-01-03', '2026-01-04'),
('ba3', '6', 'b2', 'approved', '2026-01-05', '2026-01-06'),
('ba4', '7', 'b2', 'approved', '2026-01-07', '2026-01-08');

-- 支部申请消息数据
INSERT INTO branch_application_messages (id, application_id, user_id, type, content, is_read) VALUES
('bam1', 'ba1', '2', 'apply', '张三申请加入第一党支部', true),
('bam2', 'ba1', '4', 'approve', '您的支部申请已批准', true),
('bam3', 'ba2', '2', 'apply', '李四申请加入第一党支部', true),
('bam4', 'ba2', '5', 'approve', '您的支部申请已批准', true),
('bam5', 'ba3', '3', 'apply', '王五申请加入第二党支部', true),
('bam6', 'ba3', '6', 'approve', '您的支部申请已批准', true),
('bam7', 'ba4', '3', 'apply', '赵六申请加入第二党支部', true),
('bam8', 'ba4', '7', 'approve', '您的支部申请已批准', true);

-- 政策宣传数据
INSERT INTO policies (id, title, content, type, publish_date, image_url, video_url, view_count, created_by) VALUES
('p1', '党的二十大精神学习', '深入学习党的二十大精神，贯彻落实党中央决策部署', '重要讲话', '2026-03-01', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20meeting%20二十大&image_size=landscape_16_9', NULL, 100, '1'),
('p2', '2026年党建工作要点', '2026年党建工作重点任务和目标', '政策法规', '2026-03-05', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20work%20plan&image_size=landscape_16_9', NULL, 80, '1'),
('p3', '优秀党员事迹报告', '宣传优秀党员的先进事迹', '先进典型', '2026-03-10', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=excellent%20party%20member&image_size=landscape_16_9', NULL, 120, '2'),
('p4', '最新党内法规解读', '解读最新颁布的党内法规', '政策法规', '2026-03-15', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20regulations&image_size=landscape_16_9', NULL, 90, '2');

-- 政策收藏数据
INSERT INTO policy_favorites (id, user_id, policy_id) VALUES
('pf1', '4', 'p1'),
('pf2', '4', 'p2'),
('pf3', '5', 'p1'),
('pf4', '6', 'p3'),
('pf5', '7', 'p4');

-- 学习资源数据
INSERT INTO study_resources (id, title, type, content, duration, image_url, video_url, created_by) VALUES
('sr1', '党史学习入门', '党史学习', '党史基础知识学习材料', 60, 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20history%20study&image_size=landscape_16_9', NULL, '1'),
('sr2', '党课教程：党的性质', '党课教程', '详细讲解党的性质和宗旨', 45, 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20class&image_size=landscape_16_9', NULL, '1'),
('sr3', '习近平新时代中国特色社会主义思想', '理论知识', '深入学习习近平新时代中国特色社会主义思想', 90, 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=xi%20thought&image_size=landscape_16_9', NULL, '2'),
('sr4', '党员纪律处分条例解读', '专题学习', '解读党员纪律处分条例', 60, 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20discipline&image_size=landscape_16_9', NULL, '2');

-- 学习进度数据
INSERT INTO study_progress (id, user_id, resource_id, progress, is_favorite, last_study_at) VALUES
('sp1', '4', 'sr1', 100, true, '2026-03-10 10:00:00'),
('sp2', '4', 'sr2', 50, false, '2026-03-11 14:00:00'),
('sp3', '5', 'sr1', 75, true, '2026-03-12 09:00:00'),
('sp4', '6', 'sr3', 100, true, '2026-03-13 16:00:00'),
('sp5', '7', 'sr4', 30, false, '2026-03-14 11:00:00');

-- 活动数据
INSERT INTO activities (id, title, content, start_time, end_time, location, organizer, image_url, status, participant_count, max_participants, summary, summary_image_url, created_by) VALUES
('act1', '党员学习会议', '开展党员学习教育活动，学习最新政策精神', '2026-03-20 09:00:00', '2026-03-20 11:00:00', '党委会议室', '党委办公室', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20meeting%20room&image_size=landscape_16_9', 'upcoming', 0, 50, NULL, NULL, '1'),
('act2', '志愿服务活动', '组织党员开展社区志愿服务活动', '2026-03-15 14:00:00', '2026-03-15 17:00:00', '阳光社区', '第一党支部', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=volunteer%20activity&image_size=landscape_16_9', 'completed', 10, 30, '活动圆满完成，党员们积极参与，获得社区居民好评', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=volunteer%20activity%20summary&image_size=landscape_16_9', '2'),
('act3', '支部组织生活会', '召开支部组织生活会，开展批评与自我批评', '2026-03-25 19:00:00', '2026-03-25 21:00:00', '支部会议室', '第二党支部', 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=party%20organization%20meeting&image_size=landscape_16_9', 'upcoming', 0, 20, NULL, NULL, '3');

-- 活动报名数据
INSERT INTO activity_registrations (id, user_id, activity_id, is_checked_in, check_in_time, registered_at) VALUES
('ar1', '4', 'act2', true, '2026-03-15 14:05:00', '2026-03-10 09:00:00'),
('ar2', '5', 'act2', true, '2026-03-15 14:06:00', '2026-03-10 09:30:00'),
('ar3', '6', 'act2', true, '2026-03-15 14:07:00', '2026-03-10 10:00:00'),
('ar4', '7', 'act2', true, '2026-03-15 14:08:00', '2026-03-10 10:30:00'),
('ar5', '4', 'act1', false, NULL, '2026-03-15 09:00:00'),
('ar6', '5', 'act1', false, NULL, '2026-03-15 09:30:00'),
('ar7', '6', 'act3', false, NULL, '2026-03-20 10:00:00'),
('ar8', '7', 'act3', false, NULL, '2026-03-20 10:30:00');

-- 党费缴纳数据
INSERT INTO dues_payments (id, user_id, payment_month, amount, payment_method, payment_status, payment_date) VALUES
('dp1', '4', '2026-03-01', 10.00, 'online', 'paid', '2026-03-05 10:00:00'),
('dp2', '5', '2026-03-01', 10.00, 'online', 'paid', '2026-03-06 11:00:00'),
('dp3', '6', '2026-03-01', 10.00, 'offline', 'paid', '2026-03-07 14:00:00'),
('dp4', '7', '2026-03-01', 10.00, NULL, 'pending', NULL),
('dp5', '8', '2026-03-01', 10.00, NULL, 'overdue', NULL),
('dp6', '4', '2026-02-01', 10.00, 'online', 'paid', '2026-02-05 10:00:00'),
('dp7', '5', '2026-02-01', 10.00, 'online', 'paid', '2026-02-06 11:00:00'),
('dp8', '6', '2026-02-01', 10.00, 'offline', 'paid', '2026-02-07 14:00:00');

-- 消息数据
INSERT INTO messages (id, sender_id, recipient_id, content, is_read, created_at) VALUES
('m1', '1', '2', '你好，第一支部管理员！', true, '2026-03-10 10:00:00'),
('m2', '2', '1', '你好，系统管理员！', true, '2026-03-10 10:01:00'),
('m3', '1', '3', '你好，第二支部管理员！', true, '2026-03-10 10:02:00'),
('m4', '3', '1', '你好，系统管理员！', true, '2026-03-10 10:03:00'),
('m5', '2', '4', '张三同志，请注意参加本周的支部会议。', true, '2026-03-10 10:04:00'),
('m6', '4', '2', '好的，我会准时参加。', true, '2026-03-10 10:05:00'),
('m7', '3', '6', '王五同志，第二党支部的学习计划已经发布。', true, '2026-03-10 10:06:00'),
('m8', '6', '3', '收到，我会查看学习计划。', true, '2026-03-10 10:07:00'),
('m9', '4', '5', '李四同志，一起准备党课材料吧？', true, '2026-03-10 10:08:00'),
('m10', '5', '4', '好啊，张三同志，我们明天下午开始。', true, '2026-03-10 10:09:00'),
('m11', '6', '7', '赵六同志，周末一起参加志愿活动吧？', false, '2026-03-10 10:10:00'),
('m12', '1', '4', '张三同志，你的学习进度不错，继续保持！', false, '2026-03-10 10:11:00'),
('m13', '2', '5', '李四同志，党费已经缴纳了吗？', false, '2026-03-10 10:12:00'),
('m14', '3', '7', '赵六同志，第二党支部的活动安排好了。', false, '2026-03-10 10:13:00'),
('m15', '4', '1', '系统管理员，我想申请成为入党积极分子。', false, '2026-03-10 10:14:00');

-- 更新活动参与人数
UPDATE activities a
SET a.participant_count = (
    SELECT COUNT(*) FROM activity_registrations ar WHERE ar.activity_id = a.id
);

-- 查看数据统计
SELECT '用户数量' AS type, COUNT(*) AS count FROM users
UNION ALL
SELECT '支部数量' AS type, COUNT(*) AS count FROM branches
UNION ALL
SELECT '政策数量' AS type, COUNT(*) AS count FROM policies
UNION ALL
SELECT '学习资源数量' AS type, COUNT(*) AS count FROM study_resources
UNION ALL
SELECT '活动数量' AS type, COUNT(*) AS count FROM activities
UNION ALL
SELECT '党费记录数量' AS type, COUNT(*) AS count FROM dues_payments
UNION ALL
SELECT '消息数量' AS type, COUNT(*) AS count FROM messages;
