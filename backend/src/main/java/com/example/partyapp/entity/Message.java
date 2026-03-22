package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("messages")
public class Message {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String senderId;

    private String recipientId;

    private String content;

    private Boolean isRead;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
