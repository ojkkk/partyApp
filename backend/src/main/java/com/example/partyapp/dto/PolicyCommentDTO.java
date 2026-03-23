package com.example.partyapp.dto;

import com.example.partyapp.entity.PolicyComment;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class PolicyCommentDTO {
    private String id;
    private String policyId;
    private String userId;
    private String content;
    private LocalDateTime createdAt;
    private String userName;
    private String userBranch;
    private String userAvatar;

    public PolicyCommentDTO(PolicyComment comment, String userName, String userBranch, String userAvatar) {
        this.id = comment.getId();
        this.policyId = comment.getPolicyId();
        this.userId = comment.getUserId();
        this.content = comment.getContent();
        this.createdAt = comment.getCreatedAt();
        this.userName = userName;
        this.userBranch = userBranch;
        this.userAvatar = userAvatar;
    }
}
