package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("policy_favorites")
public class PolicyFavorite {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String userId;

    private String policyId;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}