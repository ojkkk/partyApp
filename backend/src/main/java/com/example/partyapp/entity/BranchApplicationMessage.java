package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("branch_application_messages")
public class BranchApplicationMessage {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String applicationId;

    private String userId;

    private String type;

    private String content;

    private Boolean isRead;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
