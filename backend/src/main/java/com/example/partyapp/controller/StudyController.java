package com.example.partyapp.controller;

import com.example.partyapp.annotation.RequireRole;
import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.StudyStats;
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
}
