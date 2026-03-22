package com.example.partyapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ActivityCreateRequest {
    @NotBlank(message = "活动标题不能为空")
    private String title;

    @NotBlank(message = "活动内容不能为空")
    private String content;

    @NotBlank(message = "开始时间不能为空")
    private String startTime;

    @NotBlank(message = "结束时间不能为空")
    private String endTime;

    @NotBlank(message = "活动地点不能为空")
    private String location;

    @NotBlank(message = "组织者不能为空")
    private String organizer;

    private String imageUrl;

    private String status;

    @NotNull(message = "最大报名人数不能为空")
    private Integer maxParticipants;
}