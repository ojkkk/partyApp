package com.example.partyapp.controller;

import com.example.partyapp.annotation.RequireRole;
import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.PolicyCommentDTO;
import com.example.partyapp.entity.Policy;
import com.example.partyapp.entity.PolicyComment;
import com.example.partyapp.enums.Role;
import com.example.partyapp.service.PolicyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/policies")
@RequiredArgsConstructor
public class PolicyController {
    private final PolicyService policyService;

    @GetMapping
    public ApiResponse<List<Policy>> getPolicies(@RequestParam(required = false) String type) {
        return ApiResponse.success(policyService.getPolicies(type));
    }

    @GetMapping("/{id}")
    public ApiResponse<Policy> getPolicyDetail(@PathVariable String id) {
        Policy policy = policyService.getPolicyDetail(id);
        if (policy == null) {
            return ApiResponse.error("政策不存在");
        }
        return ApiResponse.success(policy);
    }

    @PostMapping
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Policy> createPolicy(@RequestBody Policy policy) {
        return ApiResponse.success("创建成功", policyService.createPolicy(policy));
    }

    @PutMapping("/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Policy> updatePolicy(@PathVariable String id, @RequestBody Policy policy) {
        return ApiResponse.success("更新成功", policyService.updatePolicy(id, policy));
    }

    @DeleteMapping("/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Void> deletePolicy(@PathVariable String id) {
        policyService.deletePolicy(id);
        return ApiResponse.success("删除成功", null);
    }

    @PostMapping("/{id}/favorite")
    public ApiResponse<Boolean> toggleFavorite(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            boolean isFavorite = policyService.toggleFavorite(userId, id);
            return ApiResponse.success(isFavorite);
        } catch (Exception e) {
            return ApiResponse.error("操作失败");
        }
    }

    @GetMapping("/favorites")
    public ApiResponse<List<Policy>> getFavorites() {
        try {
            String userId = UserContext.getUserId();
            return ApiResponse.success(policyService.getFavorites(userId));
        } catch (Exception e) {
            return ApiResponse.error("获取收藏失败");
        }
    }

    @PostMapping("/{id}/comments")
    public ApiResponse<PolicyCommentDTO> addComment(@PathVariable String id, @RequestBody CommentRequest request) {
        try {
            String userId = UserContext.getUserId();
            PolicyCommentDTO comment = policyService.addComment(userId, id, request.getContent());
            return ApiResponse.success(comment);
        } catch (Exception e) {
            return ApiResponse.error("添加评论失败");
        }
    }

    private static class CommentRequest {
        private String content;

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }

    @GetMapping("/{id}/comments")
    public ApiResponse<List<PolicyCommentDTO>> getComments(@PathVariable String id) {
        try {
            List<PolicyCommentDTO> comments = policyService.getComments(id);
            return ApiResponse.success(comments);
        } catch (Exception e) {
            return ApiResponse.error("获取评论失败");
        }
    }
}
