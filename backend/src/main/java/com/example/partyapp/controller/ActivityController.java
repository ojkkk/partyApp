package com.example.partyapp.controller;

import com.example.partyapp.annotation.RequireRole;
import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ActivityCreateRequest;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.entity.Activity;
import com.example.partyapp.enums.Role;
import com.example.partyapp.service.ActivityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/activities")
@RequiredArgsConstructor
public class ActivityController {
    private final ActivityService activityService;

    @GetMapping
    public ApiResponse<List<Activity>> getActivities(@RequestParam(required = false) String status) {
        return ApiResponse.success(activityService.getActivities(status));
    }

    @GetMapping("/my")
    public ApiResponse<List<Activity>> getMyActivities() {
        try {
            String userId = UserContext.getUserId();
            return ApiResponse.success(activityService.getMyActivities(userId));
        } catch (Exception e) {
            return ApiResponse.error("获取我的活动失败");
        }
    }

    @GetMapping("/{id}")
    public ApiResponse<Activity> getActivityDetail(@PathVariable String id) {
        Activity activity = activityService.getActivityDetail(id);
        if (activity == null) {
            return ApiResponse.error("活动不存在");
        }
        return ApiResponse.success(activity);
    }

    @PostMapping
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Activity> createActivity(@Valid @RequestBody ActivityCreateRequest request) {
        try {
            String userId = UserContext.getUserId();
            return ApiResponse.success("创建成功", activityService.createActivity(request, userId));
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PutMapping("/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Activity> updateActivity(@PathVariable String id, @RequestBody Activity activity) {
        return ApiResponse.success("更新成功", activityService.updateActivity(id, activity));
    }

    @DeleteMapping("/{id}")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Void> deleteActivity(@PathVariable String id) {
        activityService.deleteActivity(id);
        return ApiResponse.success("删除成功", null);
    }

    @PostMapping("/{id}/register")
    public ApiResponse<Boolean> registerActivity(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            activityService.registerActivity(userId, id);
            return ApiResponse.success("报名成功", true);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @DeleteMapping("/{id}/register")
    public ApiResponse<Boolean> cancelRegistration(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            activityService.cancelRegistration(userId, id);
            return ApiResponse.success("取消报名成功", false);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/checkin")
    public ApiResponse<Boolean> checkIn(@PathVariable String id) {
        try {
            String userId = UserContext.getUserId();
            activityService.checkIn(userId, id);
            return ApiResponse.success("签到成功", true);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/summary")
    @RequireRole({Role.ADMIN, Role.BRANCH_ADMIN})
    public ApiResponse<Boolean> uploadSummary(@PathVariable String id, 
                                               @RequestParam String summary,
                                               @RequestParam(required = false) String summaryImageUrl) {
        try {
            activityService.uploadSummary(id, summary, summaryImageUrl);
            return ApiResponse.success("上传总结成功", true);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @GetMapping("/{id}/participants")
    public ApiResponse<List<Map<String, Object>>> getActivityParticipants(@PathVariable String id) {
        try {
            return ApiResponse.success(activityService.getActivityParticipants(id));
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }
}
