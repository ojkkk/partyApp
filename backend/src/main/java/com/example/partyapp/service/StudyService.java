package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.dto.StudyStats;
import com.example.partyapp.entity.StudyProgress;
import com.example.partyapp.entity.StudyResource;
import com.example.partyapp.mapper.StudyProgressMapper;
import com.example.partyapp.mapper.StudyResourceMapper;
import com.example.partyapp.mapper.UserMapper;
import com.example.partyapp.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

@Service
@RequiredArgsConstructor
public class StudyService {
    private final StudyResourceMapper studyResourceMapper;
    private final StudyProgressMapper studyProgressMapper;
    private final UserMapper userMapper;

    public List<StudyResource> getResources(String type) {
        LambdaQueryWrapper<StudyResource> wrapper = new LambdaQueryWrapper<>();
        if (type != null && !type.equals("全部")) {
            wrapper.eq(StudyResource::getType, type);
        }
        wrapper.orderByDesc(StudyResource::getCreatedAt);
        return studyResourceMapper.selectList(wrapper);
    }

    public StudyResource getResourceDetail(String id) {
        return studyResourceMapper.selectById(id);
    }

    public StudyResource createResource(StudyResource resource) {
        studyResourceMapper.insert(resource);
        return resource;
    }

    public StudyResource updateResource(String id, StudyResource resource) {
        resource.setId(id);
        studyResourceMapper.updateById(resource);
        return resource;
    }

    public void deleteResource(String id) {
        studyResourceMapper.deleteById(id);
    }

    @Transactional
    public void updateProgress(String userId, String resourceId, Integer progress, Integer duration) {
        LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyProgress::getUserId, userId)
               .eq(StudyProgress::getResourceId, resourceId);
        StudyProgress studyProgress = studyProgressMapper.selectOne(wrapper);

        if (studyProgress == null) {
            studyProgress = new StudyProgress();
            studyProgress.setUserId(userId);
            studyProgress.setResourceId(resourceId);
            studyProgress.setProgress(Math.min(100, Math.max(0, progress)));
            studyProgress.setIsFavorite(false);
            studyProgress.setLastStudyAt(LocalDateTime.now());
            studyProgress.setStudyDuration(duration != null ? duration : 0);
            studyProgressMapper.insert(studyProgress);
        } else {
            studyProgress.setProgress(Math.min(100, Math.max(0, progress)));
            studyProgress.setLastStudyAt(LocalDateTime.now());
            if (duration != null) {
                studyProgress.setStudyDuration(studyProgress.getStudyDuration() + duration);
            }
            studyProgressMapper.updateById(studyProgress);
        }
    }

    @Transactional
    public boolean toggleFavorite(String userId, String resourceId) {
        LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyProgress::getUserId, userId)
               .eq(StudyProgress::getResourceId, resourceId);
        StudyProgress studyProgress = studyProgressMapper.selectOne(wrapper);

        if (studyProgress == null) {
            studyProgress = new StudyProgress();
            studyProgress.setUserId(userId);
            studyProgress.setResourceId(resourceId);
            studyProgress.setProgress(0);
            studyProgress.setIsFavorite(true);
            studyProgressMapper.insert(studyProgress);
            return true;
        } else {
            studyProgress.setIsFavorite(!studyProgress.getIsFavorite());
            studyProgressMapper.updateById(studyProgress);
            return studyProgress.getIsFavorite();
        }
    }

    public StudyStats getStudyStats(String userId) {
        List<StudyResource> allResources = studyResourceMapper.selectList(null);
        int totalCourses = allResources.size();
        
        LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyProgress::getUserId, userId);
        List<StudyProgress> progresses = studyProgressMapper.selectList(wrapper);
        
        int completedCourses = (int) progresses.stream()
                .filter(p -> p.getProgress() != null && p.getProgress() == 100)
                .count();
        
        // 使用真实的学习时长数据，单位为分钟
        int totalDuration = progresses.stream()
                .mapToInt(p -> p.getStudyDuration() != null ? p.getStudyDuration() / 60 : 0)
                .sum();
        
        double totalProgress = progresses.isEmpty() ? 0 : 
            progresses.stream()
                .mapToInt(p -> p.getProgress() != null ? p.getProgress() : 0)
                .average()
                .orElse(0);
        
        return new StudyStats(totalCourses, completedCourses, totalDuration, totalProgress);
    }

    public List<StudyResource> getFavorites(String userId) {
        LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyProgress::getUserId, userId)
               .eq(StudyProgress::getIsFavorite, true);
        List<StudyProgress> progresses = studyProgressMapper.selectList(wrapper);
        
        List<String> resourceIds = progresses.stream().map(StudyProgress::getResourceId).toList();
        if (resourceIds.isEmpty()) {
            return List.of();
        }
        
        return studyResourceMapper.selectBatchIds(resourceIds);
    }

    public List<Map<String, Object>> getAllUserStudyStats() {
        // 获取所有用户
        List<User> users = userMapper.selectList(null);
        List<Map<String, Object>> statsList = new ArrayList<>();
        
        // 对每个用户计算学习统计
        for (User user : users) {
            Map<String, Object> userStats = new HashMap<>();
            userStats.put("userId", user.getId());
            userStats.put("username", user.getUsername());
            userStats.put("name", user.getName());
            userStats.put("role", user.getRole());
            userStats.put("branch", user.getBranch());
            
            // 计算该用户的学习统计
            StudyStats stats = getStudyStats(user.getId());
            userStats.put("totalCourses", stats.getTotalCourses());
            userStats.put("completedCourses", stats.getCompletedCourses());
            userStats.put("totalDuration", stats.getTotalDuration());
            userStats.put("totalProgress", stats.getTotalProgress());
            
            // 添加真实学习时长
            LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(StudyProgress::getUserId, user.getId());
            List<StudyProgress> progresses = studyProgressMapper.selectList(wrapper);
            int realStudyDuration = progresses.stream()
                    .mapToInt(p -> p.getStudyDuration() != null ? p.getStudyDuration() / 60 : 0)
                    .sum();
            userStats.put("studyDuration", realStudyDuration);
            
            statsList.add(userStats);
        }
        
        return statsList;
    }

    public Map<String, Object> getResourceProgress(String userId, String resourceId) {
        LambdaQueryWrapper<StudyProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyProgress::getUserId, userId)
               .eq(StudyProgress::getResourceId, resourceId);
        StudyProgress studyProgress = studyProgressMapper.selectOne(wrapper);
        
        Map<String, Object> result = new HashMap<>();
        if (studyProgress != null) {
            result.put("progress", studyProgress.getProgress());
            result.put("studyDuration", studyProgress.getStudyDuration());
        } else {
            result.put("progress", 0);
            result.put("studyDuration", 0);
        }
        return result;
    }
}