package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.dto.ActivityCreateRequest;
import com.example.partyapp.entity.Activity;
import com.example.partyapp.entity.ActivityRegistration;
import com.example.partyapp.mapper.ActivityMapper;
import com.example.partyapp.mapper.ActivityRegistrationMapper;
import com.example.partyapp.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ActivityService {
    private final ActivityMapper activityMapper;
    private final ActivityRegistrationMapper activityRegistrationMapper;
    private final UserMapper userMapper;

    // 计算活动状态
    private String calculateActivityStatus(LocalDateTime startTime, LocalDateTime endTime) {
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(startTime)) {
            return "upcoming";
        } else if (now.isAfter(endTime)) {
            return "completed";
        } else {
            return "ongoing";
        }
    }

    // 更新活动状态
    private void updateActivityStatus(Activity activity) {
        String status = calculateActivityStatus(activity.getStartTime(), activity.getEndTime());
        if (!status.equals(activity.getStatus())) {
            activity.setStatus(status);
            activityMapper.updateById(activity);
        }
    }

    public List<Activity> getActivities(String status) {
        List<Activity> activities = activityMapper.selectList(null);
        // 更新所有活动的状态
        for (Activity activity : activities) {
            updateActivityStatus(activity);
        }
        
        // 按状态过滤
        if (status != null) {
            activities = activities.stream()
                    .filter(activity -> status.equals(activity.getStatus()))
                    .collect(Collectors.toList());
        }
        
        // 按开始时间倒序排序
        activities.sort((a1, a2) -> a2.getStartTime().compareTo(a1.getStartTime()));
        return activities;
    }

    public List<Activity> getMyActivities(String userId) {
        String role = com.example.partyapp.context.UserContext.getRole();
        
        System.out.println("Getting my activities for user: " + userId + ", role: " + role);
        
        List<Activity> activities;
        if ("admin".equals(role) || "branch_admin".equals(role)) {
            LambdaQueryWrapper<Activity> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(Activity::getCreatedBy, userId);
            activities = activityMapper.selectList(wrapper);
            System.out.println("Found " + activities.size() + " created activities for user: " + userId);
        } else {
            LambdaQueryWrapper<ActivityRegistration> regWrapper = new LambdaQueryWrapper<>();
            regWrapper.eq(ActivityRegistration::getUserId, userId);
            List<ActivityRegistration> registrations = activityRegistrationMapper.selectList(regWrapper);
            System.out.println("Found " + registrations.size() + " registrations for user: " + userId);
            
            List<String> activityIds = registrations.stream().map(ActivityRegistration::getActivityId).toList();
            if (activityIds.isEmpty()) {
                return List.of();
            }
            
            activities = activityMapper.selectBatchIds(activityIds);
        }
        
        // 更新活动状态
        for (Activity activity : activities) {
            updateActivityStatus(activity);
        }
        
        // 按开始时间倒序排序
        activities.sort((a1, a2) -> a2.getStartTime().compareTo(a1.getStartTime()));
        return activities;
    }

    public Activity getActivityDetail(String id) {
        Activity activity = activityMapper.selectById(id);
        if (activity != null) {
            updateActivityStatus(activity);
        }
        return activity;
    }

    @Transactional
    public Activity createActivity(ActivityCreateRequest request, String userId) {
        Activity activity = new Activity();
        activity.setTitle(request.getTitle());
        activity.setContent(request.getContent());
        
        try {
            if (request.getStartTime().contains(" ")) {
                activity.setStartTime(java.time.LocalDateTime.parse(request.getStartTime(), 
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            } else {
                activity.setStartTime(java.time.LocalDateTime.parse(request.getStartTime() + " 00:00:00", 
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            }
            
            if (request.getEndTime().contains(" ")) {
                activity.setEndTime(java.time.LocalDateTime.parse(request.getEndTime(), 
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            } else {
                activity.setEndTime(java.time.LocalDateTime.parse(request.getEndTime() + " 23:59:59", 
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            }
        } catch (Exception e) {
            throw new RuntimeException("时间格式不正确");
        }
        
        activity.setLocation(request.getLocation());
        activity.setOrganizer(request.getOrganizer());
        activity.setImageUrl(request.getImageUrl());
        // 自动计算初始状态
        activity.setStatus(calculateActivityStatus(activity.getStartTime(), activity.getEndTime()));
        activity.setParticipantCount(0);
        activity.setMaxParticipants(request.getMaxParticipants());
        activity.setCreatedBy(userId);
        
        activityMapper.insert(activity);
        return activity;
    }

    public Activity updateActivity(String id, Activity activity) {
        // 移除状态字段，防止手动修改
        Activity existingActivity = activityMapper.selectById(id);
        if (existingActivity != null) {
            // 保存原始状态
            String originalStatus = existingActivity.getStatus();
            // 更新除状态外的其他字段
            existingActivity.setTitle(activity.getTitle());
            existingActivity.setContent(activity.getContent());
            existingActivity.setStartTime(activity.getStartTime());
            existingActivity.setEndTime(activity.getEndTime());
            existingActivity.setLocation(activity.getLocation());
            existingActivity.setOrganizer(activity.getOrganizer());
            existingActivity.setImageUrl(activity.getImageUrl());
            existingActivity.setMaxParticipants(activity.getMaxParticipants());
            existingActivity.setSummary(activity.getSummary());
            existingActivity.setSummaryImageUrl(activity.getSummaryImageUrl());
            
            // 重新计算状态
            existingActivity.setStatus(calculateActivityStatus(existingActivity.getStartTime(), existingActivity.getEndTime()));
            
            activityMapper.updateById(existingActivity);
            return existingActivity;
        }
        return null;
    }

    public void deleteActivity(String id) {
        activityMapper.deleteById(id);
    }

    @Transactional
    public boolean registerActivity(String userId, String activityId) {
        Activity activity = activityMapper.selectById(activityId);
        if (activity == null) {
            throw new RuntimeException("活动不存在");
        }
        
        // 更新活动状态
        updateActivityStatus(activity);
        
        if (!"upcoming".equals(activity.getStatus())) {
            throw new RuntimeException("活动不可报名");
        }
        if (activity.getParticipantCount() >= activity.getMaxParticipants()) {
            throw new RuntimeException("报名人数已满");
        }

        LambdaQueryWrapper<ActivityRegistration> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ActivityRegistration::getUserId, userId)
               .eq(ActivityRegistration::getActivityId, activityId);
        if (activityRegistrationMapper.selectCount(wrapper) > 0) {
            throw new RuntimeException("已报名该活动");
        }

        ActivityRegistration registration = new ActivityRegistration();
        registration.setUserId(userId);
        registration.setActivityId(activityId);
        registration.setIsCheckedIn(false);
        activityRegistrationMapper.insert(registration);

        activity.setParticipantCount(activity.getParticipantCount() + 1);
        activityMapper.updateById(activity);

        return true;
    }

    @Transactional
    public boolean cancelRegistration(String userId, String activityId) {
        LambdaQueryWrapper<ActivityRegistration> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ActivityRegistration::getUserId, userId)
               .eq(ActivityRegistration::getActivityId, activityId);
        ActivityRegistration registration = activityRegistrationMapper.selectOne(wrapper);
        
        if (registration == null) {
            throw new RuntimeException("未报名该活动");
        }

        activityRegistrationMapper.deleteById(registration.getId());

        Activity activity = activityMapper.selectById(activityId);
        if (activity != null && activity.getParticipantCount() > 0) {
            activity.setParticipantCount(activity.getParticipantCount() - 1);
            activityMapper.updateById(activity);
        }

        return true;
    }

    @Transactional
    public boolean checkIn(String userId, String activityId) {
        LambdaQueryWrapper<ActivityRegistration> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ActivityRegistration::getUserId, userId)
               .eq(ActivityRegistration::getActivityId, activityId);
        ActivityRegistration registration = activityRegistrationMapper.selectOne(wrapper);
        
        if (registration == null) {
            throw new RuntimeException("未报名该活动");
        }
        if (registration.getIsCheckedIn()) {
            throw new RuntimeException("已签到");
        }

        // 检查活动状态是否为进行中
        Activity activity = activityMapper.selectById(activityId);
        if (activity != null) {
            updateActivityStatus(activity);
            if (!"ongoing".equals(activity.getStatus())) {
                throw new RuntimeException("活动当前不可签到");
            }
        }

        registration.setIsCheckedIn(true);
        registration.setCheckInTime(LocalDateTime.now());
        activityRegistrationMapper.updateById(registration);

        return true;
    }

    @Transactional
    public boolean uploadSummary(String id, String summary, String summaryImageUrl) {
        Activity activity = activityMapper.selectById(id);
        if (activity == null) {
            throw new RuntimeException("活动不存在");
        }
        activity.setSummary(summary);
        activity.setSummaryImageUrl(summaryImageUrl);
        activityMapper.updateById(activity);
        return true;
    }

    // 获取活动的报名和签到情况
    public List<Map<String, Object>> getActivityParticipants(String activityId) {
        LambdaQueryWrapper<ActivityRegistration> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ActivityRegistration::getActivityId, activityId);
        List<ActivityRegistration> registrations = activityRegistrationMapper.selectList(wrapper);
        
        return registrations.stream().map(registration -> {
            Map<String, Object> participant = new java.util.HashMap<>();
            participant.put("registrationId", registration.getId());
            participant.put("userId", registration.getUserId());
            participant.put("isCheckedIn", registration.getIsCheckedIn());
            participant.put("checkInTime", registration.getCheckInTime());
            participant.put("registeredAt", registration.getRegisteredAt());
            
            // 获取用户信息
            com.example.partyapp.entity.User user = userMapper.selectById(registration.getUserId());
            if (user != null) {
                participant.put("username", user.getUsername());
                participant.put("name", user.getName());
                participant.put("phone", user.getPhone());
                participant.put("branch", user.getBranch());
            }
            
            return participant;
        }).collect(Collectors.toList());
    }
}