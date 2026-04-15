package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("policies")
public class Policy {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String title;

    private String content;

    private String type;

    private LocalDate publishDate;

    private String imageUrl;

    private String videoUrl;

    private String summary;

    private String tags;

    private String publisher;

    private Integer viewCount;

    private String createdBy;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
