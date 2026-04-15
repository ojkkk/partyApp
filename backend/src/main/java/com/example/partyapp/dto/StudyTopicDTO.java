package com.example.partyapp.dto;

import com.example.partyapp.entity.StudyResource;
import lombok.Data;
import java.util.List;

/**
 * 专题学习目录（带子资源列表）
 */
@Data
public class StudyTopicDTO {
    private String id;
    private String title;
    private String content;       // 目录简介/描述
    private String imageUrl;       // 目录封面图
    private String createdBy;
    private String createdAt;
    private Integer childCount;    // 子资源数量
    private List<StudyResource> children; // 子资源列表
}
