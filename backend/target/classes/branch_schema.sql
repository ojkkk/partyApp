-- 支部表
CREATE TABLE IF NOT EXISTS branches (
  id VARCHAR(36) PRIMARY KEY COMMENT '支部ID',
  name VARCHAR(100) UNIQUE NOT NULL COMMENT '支部名称',
  admin_id VARCHAR(36) NOT NULL COMMENT '管理员ID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX idx_name (name),
  INDEX idx_admin_id (admin_id),
  FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支部表';

-- 支部申请表
CREATE TABLE IF NOT EXISTS branch_applications (
  id VARCHAR(36) PRIMARY KEY COMMENT '申请ID',
  user_id VARCHAR(36) NOT NULL COMMENT '申请人ID',
  branch_id VARCHAR(36) NOT NULL COMMENT '申请支部ID',
  status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending' COMMENT '申请状态',
  apply_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '申请日期',
  approve_date TIMESTAMP NULL COMMENT '审批日期',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY uk_user_branch (user_id, branch_id),
  INDEX idx_user_id (user_id),
  INDEX idx_branch_id (branch_id),
  INDEX idx_status (status),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支部申请表';

-- 支部申请消息表
CREATE TABLE IF NOT EXISTS branch_application_messages (
  id VARCHAR(36) PRIMARY KEY COMMENT '消息ID',
  application_id VARCHAR(36) NOT NULL COMMENT '申请ID',
  user_id VARCHAR(36) NOT NULL COMMENT '接收用户ID',
  type ENUM('apply', 'approve', 'reject') NOT NULL COMMENT '消息类型',
  content TEXT NOT NULL COMMENT '消息内容',
  is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  INDEX idx_application_id (application_id),
  INDEX idx_user_id (user_id),
  INDEX idx_is_read (is_read),
  FOREIGN KEY (application_id) REFERENCES branch_applications(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支部申请消息表';
