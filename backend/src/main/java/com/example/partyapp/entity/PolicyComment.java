package com.example.partyapp.entity;

import lombok.Data;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;

import java.time.LocalDateTime;

@Data
@TableName("policy_comments")
public class PolicyComment {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String policyId;
    private String userId;
    private String content;
    private LocalDateTime createdAt;
}
