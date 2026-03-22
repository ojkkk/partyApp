-- 创建数据库
CREATE DATABASE IF NOT EXISTS partyapp DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE partyapp;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) PRIMARY KEY COMMENT '用户ID',
  username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
  password VARCHAR(255) NOT NULL COMMENT '密码（加密存储）',
  name VARCHAR(50) NOT NULL COMMENT '姓名',
  role ENUM('admin', 'branch_admin', 'member') NOT NULL DEFAULT 'member' COMMENT '角色',
  party_id VARCHAR(50) NOT NULL COMMENT '党员编号',
  branch VARCHAR(100) COMMENT '所在支部',
  join_date DATE NOT NULL COMMENT '入党日期',
  phone VARCHAR(20) NOT NULL COMMENT '手机号',
  email VARCHAR(100) NOT NULL COMMENT '邮箱',
  avatar BLOB COMMENT '头像图片',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX idx_username (username),
  INDEX idx_branch (branch),
  INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 政策宣传表
CREATE TABLE IF NOT EXISTS policies (
  id VARCHAR(36) PRIMARY KEY COMMENT '政策ID',
  title VARCHAR(200) NOT NULL COMMENT '标题',
  content TEXT NOT NULL COMMENT '内容',
  type ENUM('新闻动态', '政策法规', '重要讲话', '先进典型') NOT NULL COMMENT '类型',
  publish_date DATE NOT NULL COMMENT '发布日期',
  image_url VARCHAR(500) COMMENT '图片URL',
  video_url VARCHAR(500) COMMENT '视频URL',
  view_count INT DEFAULT 0 COMMENT '浏览次数',
  created_by VARCHAR(36) COMMENT '创建人ID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX idx_type (type),
  INDEX idx_publish_date (publish_date),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='政策宣传表';

-- 政策收藏表
CREATE TABLE IF NOT EXISTS policy_favorites (
  id VARCHAR(36) PRIMARY KEY COMMENT '收藏ID',
  user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
  policy_id VARCHAR(36) NOT NULL COMMENT '政策ID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  UNIQUE KEY uk_user_policy (user_id, policy_id),
  INDEX idx_user_id (user_id),
  INDEX idx_policy_id (policy_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='政策收藏表';

-- 学习资源表
CREATE TABLE IF NOT EXISTS study_resources (
  id VARCHAR(36) PRIMARY KEY COMMENT '资源ID',
  title VARCHAR(200) NOT NULL COMMENT '标题',
  type ENUM('党史学习', '党课教程', '理论知识', '专题学习') NOT NULL COMMENT '类型',
  content TEXT NOT NULL COMMENT '内容',
  duration INT NOT NULL COMMENT '学习时长（分钟）',
  image_url VARCHAR(500) COMMENT '图片URL',
  video_url VARCHAR(500) COMMENT '视频URL',
  created_by VARCHAR(36) COMMENT '创建人ID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX idx_type (type),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习资源表';

-- 学习进度表
CREATE TABLE IF NOT EXISTS study_progress (
  id VARCHAR(36) PRIMARY KEY COMMENT '进度ID',
  user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
  resource_id VARCHAR(36) NOT NULL COMMENT '资源ID',
  progress INT DEFAULT 0 COMMENT '学习进度（0-100）',
  is_favorite BOOLEAN DEFAULT FALSE COMMENT '是否收藏',
  last_study_at TIMESTAMP NULL COMMENT '最后学习时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY uk_user_resource (user_id, resource_id),
  INDEX idx_user_id (user_id),
  INDEX idx_resource_id (resource_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES study_resources(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习进度表';

-- 活动表
CREATE TABLE IF NOT EXISTS activities (
  id VARCHAR(36) PRIMARY KEY COMMENT '活动ID',
  title VARCHAR(200) NOT NULL COMMENT '活动标题',
  content TEXT NOT NULL COMMENT '活动内容',
  start_time DATETIME NOT NULL COMMENT '开始时间',
  end_time DATETIME NOT NULL COMMENT '结束时间',
  location VARCHAR(200) NOT NULL COMMENT '活动地点',
  organizer VARCHAR(100) NOT NULL COMMENT '组织者',
  image_url VARCHAR(500) COMMENT '活动图片URL',
  status ENUM('upcoming', 'ongoing', 'completed') NOT NULL DEFAULT 'upcoming' COMMENT '活动状态',
  participant_count INT DEFAULT 0 COMMENT '已报名人数',
  max_participants INT NOT NULL COMMENT '最大报名人数',
  summary TEXT COMMENT '活动总结',
  summary_image_url VARCHAR(500) COMMENT '活动总结图片URL',
  created_by VARCHAR(36) COMMENT '创建人ID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX idx_status (status),
  INDEX idx_start_time (start_time),
  INDEX idx_created_by (created_by),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='活动表';

-- 活动报名记录表
CREATE TABLE IF NOT EXISTS activity_registrations (
  id VARCHAR(36) PRIMARY KEY COMMENT '报名ID',
  user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
  activity_id VARCHAR(36) NOT NULL COMMENT '活动ID',
  is_checked_in BOOLEAN DEFAULT FALSE COMMENT '是否已签到',
  check_in_time TIMESTAMP NULL COMMENT '签到时间',
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '报名时间',
  UNIQUE KEY uk_user_activity (user_id, activity_id),
  INDEX idx_user_id (user_id),
  INDEX idx_activity_id (activity_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='活动报名记录表';

-- 消息表
CREATE TABLE IF NOT EXISTS messages (
  id VARCHAR(36) PRIMARY KEY COMMENT '消息ID',
  sender_id VARCHAR(36) NOT NULL COMMENT '发送者ID',
  recipient_id VARCHAR(36) NOT NULL COMMENT '接收者ID',
  content TEXT NOT NULL COMMENT '消息内容',
  is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  INDEX idx_sender_recipient (sender_id, recipient_id),
  INDEX idx_recipient (recipient_id),
  FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息表';

-- 插入初始数据（测试用户）
-- 注意：密码是 BCrypt 加密后的 "admin123"、"branch123"、"member123"
INSERT INTO users (id, username, password, name, role, party_id, branch, join_date, phone, email) VALUES
('1', 'admin', '$2a$10$eWxp7YAAGAbod2Ot8zVZV.3RtDvdJjnsPZrzj2P6yHHNknfNtgZvW', '系统管理员', 'admin', '001', '党委', '2020-01-01', '13800138000', 'admin@example.com'),
('2', 'branch', '$2a$10$msH5RxcXOJ1S.b9P8ilh/uGxzwYKenQe1KX96eKJvSRG3erE3XUPC', '支部管理员', 'branch_admin', '002', '第一党支部', '2020-02-01', '13800138001', 'branch@example.com'),
('3', 'member', '$2a$10$.PNdBOJHj9VahAVjubxnTen7RXGGYMFwMob./nr4J/8qZ3t2zARqG', '普通党员', 'member', '003', '第一党支部', '2020-03-01', '13800138002', 'member@example.com')
ON DUPLICATE KEY UPDATE username=username;