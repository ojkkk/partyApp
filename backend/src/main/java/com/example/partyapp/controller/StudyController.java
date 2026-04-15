package com.example.partyapp.controller;

import com.example.partyapp.annotation.RequireRole;
import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.StudyStats;
import com.example.partyapp.dto.StudyTopicDTO;
import com.example.partyapp.entity.StudyResource;
import com.example.partyapp.enums.Role;
import com.example.partyapp.service.StudyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/study")
@RequiredArgsConstructor
public class StudyController {
    private final StudyService studyService;

    @GetMapping("/resources")
    public ApiResponse<List<StudyResource>> getResources(@RequestParam(required = false) String type) {
        return ApiResponse.success(studyService.getResources(type));
    }

    @GetMapping("/resources/{id}")
    public ApiResponse<StudyResource> getResourceDetail(@PathVariable String id) {
        StudyResource resource = studyService.getResourceDetail(id);
        if (resource == null) {
            return ApiResponse.error("资源不存在");
        }
        return ApiResponse.success(resource);
    }

    // ===== 专题目录 API =====

    /**
     * 获取专题目录嵌套列表（专题 + 子资源）
     */
    @GetMapping("/topics")
    public ApiResponse<List<StudyTopicDTO>> getTopics() {
        return ApiResponse.success(studyService.getTopicsWithChildren());
    }

    /**
     * 获取某专题下的子资源
     */
    @GetMapping("/topics/{topicId}/children")
    public ApiResponse<List<StudyResource>> getTopicChildren(@PathVariable String topicId) {
        return ApiResponse.success(studyService.getTopicChildren(topicId));
    }

    /**
     * 创建专题目录
     */
    @PostMapping("/topics")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<StudyResource> createTopic(@RequestBody StudyResource topic) {
        // 新建时强制使用当前登录用户ID，避免前端传空字符串导致FK约束失败
        topic.setCreatedBy(UserContext.getUserId());
        return ApiResponse.success("创建成功", studyService.createTopic(topic));
    }

    /**
     * 更新专题目录
     */
    @PutMapping("/topics/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<StudyResource> updateTopic(@PathVariable String id, @RequestBody StudyResource topic) {
        return ApiResponse.success("更新成功", studyService.updateTopic(id, topic));
    }

    /**
     * 删除专题目录
     */
    @DeleteMapping("/topics/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Void> deleteTopic(@PathVariable String id) {
        studyService.deleteTopic(id);
        return ApiResponse.success("删除成功", null);
    }

    // ===== 资源 API =====

    @PostMapping("/resources")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<StudyResource> createResource(@RequestBody StudyResource resource) {
        return ApiResponse.success("创建成功", studyService.createResource(resource));
    }

    @PutMapping("/resources/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<StudyResource> updateResource(@PathVariable String id, @RequestBody StudyResource resource) {
        return ApiResponse.success("更新成功", studyService.updateResource(id, resource));
    }

    @DeleteMapping("/resources/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Void> deleteResource(@PathVariable String id) {
        studyService.deleteResource(id);
        return ApiResponse.success("删除成功", null);
    }

    @PutMapping("/progress/{id}")
    public ApiResponse<Void> updateProgress(@PathVariable String id, @RequestParam Integer progress, @RequestParam(required = false) Integer duration) {
        try {
            String userId = UserContext.getUserId();
            studyService.updateProgress(userId, id, progress, duration);
            return ApiResponse.success("更新成功", null);
        } catch (Exception e) {
            return ApiResponse.error("更新失败");
        }
    }

    @PostMapping("/resources/{id}/favorite")
    public ApiResponse<Boolean> toggleFavorite(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            boolean isFavorite = studyService.toggleFavorite(userId, id);
            return ApiResponse.success(isFavorite);
        } catch (Exception e) {
            return ApiResponse.error("操作失败");
        }
    }

    @GetMapping("/stats")
    public ApiResponse<StudyStats> getStudyStats() {
        try {
            String userId = UserContext.getUserId();
            return ApiResponse.success(studyService.getStudyStats(userId));
        } catch (Exception e) {
            return ApiResponse.error("获取统计失败");
        }
    }

    @GetMapping("/favorites")
    public ApiResponse<List<StudyResource>> getFavorites() {
        try {
            String userId = UserContext.getUserId();
            return ApiResponse.success(studyService.getFavorites(userId));
        } catch (Exception e) {
            return ApiResponse.error("获取收藏失败");
        }
    }

    @GetMapping("/all-stats")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<List<Map<String, Object>>> getAllUserStudyStats() {
        try {
            return ApiResponse.success(studyService.getAllUserStudyStats());
        } catch (Exception e) {
            return ApiResponse.error("获取所有用户学习统计失败");
        }
    }

    @GetMapping("/progress/{id}")
    public ApiResponse<Map<String, Object>> getResourceProgress(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            Map<String, Object> progress = studyService.getResourceProgress(userId, id);
            return ApiResponse.success(progress);
        } catch (Exception e) {
            return ApiResponse.error("获取学习进度失败");
        }
    }

    /**
     * 获取当前用户的学习状态分布（扇形图数据）
     */
    @GetMapping("/my-distribution")
    public ApiResponse<Map<String, Object>> getMyLearningDistribution() {
        try {
            String userId = UserContext.getUserId();
            Map<String, Object> distribution = studyService.getUserLearningDistribution(userId);
            return ApiResponse.success(distribution);
        } catch (Exception e) {
            return ApiResponse.error("获取学习分布失败");
        }
    }

    /**
     * 获取当前用户所在支部的平均学习进度
     */
    @GetMapping("/branch-average")
    public ApiResponse<Map<String, Object>> getBranchAverageProgress() {
        try {
            String userId = UserContext.getUserId();
            Map<String, Object> branchAvg = studyService.getBranchAverageProgress(userId);
            return ApiResponse.success(branchAvg);
        } catch (Exception e) {
            return ApiResponse.error("获取支部平均进度失败");
        }
    }
}
