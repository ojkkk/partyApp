package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("study_progress")
public class StudyProgress {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String userId;

    private String resourceId;

    private Integer progress;

    private Boolean isFavorite;

    private LocalDateTime lastStudyAt;

    private Integer studyDuration;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}