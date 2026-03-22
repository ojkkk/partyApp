-- 政策评论表
CREATE TABLE IF NOT EXISTS policy_comments (
  id VARCHAR(36) PRIMARY KEY COMMENT '评论ID',
  policy_id VARCHAR(36) NOT NULL COMMENT '政策ID',
  user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
  content TEXT NOT NULL COMMENT '评论内容',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
  INDEX idx_policy_id (policy_id),
  INDEX idx_user_id (user_id),
  FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='政策评论表';
