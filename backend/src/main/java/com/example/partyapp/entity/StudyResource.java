package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("study_resources")
public class StudyResource {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String title;

    private String type;

    private String content;

    private Integer duration;

    private String imageUrl;

    private String videoUrl;

    private String parentId;

    private Integer sortOrder;

    private String createdBy;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}