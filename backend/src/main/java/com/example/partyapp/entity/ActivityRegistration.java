package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("activity_registrations")
public class ActivityRegistration {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String userId;

    private String activityId;

    private Boolean isCheckedIn;

    private LocalDateTime checkInTime;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime registeredAt;
}