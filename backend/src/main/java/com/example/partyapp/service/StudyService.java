package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.partyapp.dto.StudyStats;
import com.example.partyapp.dto.StudyTopicDTO;
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
import java.util.stream.Collectors;

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

    /**
     * 获取专题学习嵌套结构（专题目录 + 子资源列表）
     */
    public List<StudyTopicDTO> getTopicsWithChildren() {
        // 1. 查询所有专题学习顶级目录（parent_id = NULL）
        LambdaQueryWrapper<StudyResource> topicWrapper = new LambdaQueryWrapper<>();
        topicWrapper.eq(StudyResource::getType, "专题学习")
                    .isNull(StudyResource::getParentId)
                    .orderByAsc(StudyResource::getSortOrder)
                    .orderByDesc(StudyResource::getCreatedAt);
        List<StudyResource> topics = studyResourceMapper.selectList(topicWrapper);

        // 2. 查询所有子资源（parent_id != NULL）
        LambdaQueryWrapper<StudyResource> childWrapper = new LambdaQueryWrapper<>();
        childWrapper.isNotNull(StudyResource::getParentId)
                    .orderByAsc(StudyResource::getSortOrder)
                    .orderByDesc(StudyResource::getCreatedAt);
        List<StudyResource> allChildren = studyResourceMapper.selectList(childWrapper);

        // 3. 按 parentId 分组
        Map<String, List<StudyResource>> childrenMap = allChildren.stream()
            .filter(c -> c.getParentId() != null)
            .collect(Collectors.groupingBy(StudyResource::getParentId));

        // 4. 组装 DTO
        return topics.stream().map(topic -> {
            StudyTopicDTO dto = new StudyTopicDTO();
            dto.setId(topic.getId());
            dto.setTitle(topic.getTitle());
            dto.setContent(topic.getContent());
            dto.setImageUrl(topic.getImageUrl());
            dto.setCreatedBy(topic.getCreatedBy());
            dto.setCreatedAt(topic.getCreatedAt() != null ? topic.getCreatedAt().toString() : null);
            List<StudyResource> children = childrenMap.getOrDefault(topic.getId(), List.of());
            dto.setChildCount(children.size());
            dto.setChildren(children);
            return dto;
        }).collect(Collectors.toList());
    }

    public StudyResource getResourceDetail(String id) {
        return studyResourceMapper.selectById(id);
    }

    public StudyResource createResource(StudyResource resource) {
        studyResourceMapper.insert(resource);
        return resource;
    }

    /**
     * 创建专题目录（顶级，parentId 为空）
     */
    public StudyResource createTopic(StudyResource topic) {
        studyResourceMapper.insert(topic);
        return topic;
    }

    /**
     * 更新专题目录
     */
    public StudyResource updateTopic(String id, StudyResource topic) {
        topic.setId(id);
        studyResourceMapper.updateById(topic);
        return topic;
    }

    /**
     * 删除专题目录（同时删除所有子资源，外键级联）
     */
    public void deleteTopic(String id) {
        studyResourceMapper.deleteById(id); // 子资源通过外键级联删除
    }

    /**
     * 获取某个专题下的所有子资源
     */
    public List<StudyResource> getTopicChildren(String topicId) {
        LambdaQueryWrapper<StudyResource> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(StudyResource::getParentId, topicId)
               .orderByAsc(StudyResource::getSortOrder)
               .orderByDesc(StudyResource::getCreatedAt);
        return studyResourceMapper.selectList(wrapper);
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
        // 获取所有实际学习资源（排除专题学习的父级目录）
        // 先查出专题学习的父级目录ID
        QueryWrapper<StudyResource> parentWrapper = new QueryWrapper<>();
        parentWrapper.eq("parent_id", null).eq("type", "专题学习");
        List<Object> parentIds = studyResourceMapper.selectObjs(parentWrapper);
        List<String> parentIdList = parentIds.stream().map(Object::toString).toList();
        
        // 查询时排除这些父级目录
        LambdaQueryWrapper<StudyResource> resourceWrapper = new LambdaQueryWrapper<>();
        if (!parentIdList.isEmpty()) {
            resourceWrapper.notIn(StudyResource::getId, parentIdList);
        }
        // 如果没有父级目录要排除，则不添加任何过滤条件
        
        List<StudyResource> allResources = studyResourceMapper.selectList(resourceWrapper);
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
        
        // 按照已完成课程数/总课程数计算进度，保留整数
        int totalProgress = totalCourses > 0 ? (completedCourses * 100 / totalCourses) : 0;
        
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

    /**
     * 获取用户个人学习状态分布（扇形图数据）
     * 返回：未学习、正在学习（0<progress<100）、已完成（progress=100）的数量
     */
    public Map<String, Object> getUserLearningDistribution(String userId) {
        // 获取所有实际学习资源（排除专题学习的父级目录）
        // 先查出专题学习的父级目录ID
        QueryWrapper<StudyResource> parentWrapper = new QueryWrapper<>();
        parentWrapper.eq("parent_id", null).eq("type", "专题学习");
        List<Object> parentIds = studyResourceMapper.selectObjs(parentWrapper);
        List<String> parentIdList = parentIds.stream().map(Object::toString).toList();
        
        // 查询时排除这些父级目录
        LambdaQueryWrapper<StudyResource> resourceWrapper = new LambdaQueryWrapper<>();
        if (!parentIdList.isEmpty()) {
            resourceWrapper.notIn(StudyResource::getId, parentIdList);
        }
        // 如果没有父级目录要排除，则不添加任何过滤条件
        
        List<StudyResource> allResources = studyResourceMapper.selectList(resourceWrapper);
        
        // 获取该用户的所有学习进度
        LambdaQueryWrapper<StudyProgress> progressWrapper = new LambdaQueryWrapper<>();
        progressWrapper.eq(StudyProgress::getUserId, userId);
        List<StudyProgress> userProgresses = studyProgressMapper.selectList(progressWrapper);
        
        // 建立用户学习进度Map：resourceId -> progress
        Map<String, Integer> progressMap = userProgresses.stream()
            .collect(Collectors.toMap(
                StudyProgress::getResourceId,
                p -> p.getProgress() != null ? p.getProgress() : 0,
                (existing, replacement) -> existing
            ));
        
        int notStarted = 0;   // 未学习：progress = null 或 0
        int inProgress = 0;  // 正在学：0 < progress < 100
        int completed = 0;   // 已完成：progress = 100
        
        for (StudyResource resource : allResources) {
            Integer progress = progressMap.get(resource.getId());
            if (progress == null || progress == 0) {
                notStarted++;
            } else if (progress == 100) {
                completed++;
            } else {
                inProgress++;
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("notStarted", notStarted);
        result.put("inProgress", inProgress);
        result.put("completed", completed);
        result.put("total", notStarted + inProgress + completed);
        return result;
    }

    /**
     * 获取用户所在支部的平均学习进度
     */
    public Map<String, Object> getBranchAverageProgress(String userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            return Map.of("avgProgress", 0, "avgDuration", 0, "totalMembers", 0);
        }
        
        // 获取同支部所有成员
        LambdaQueryWrapper<User> userWrapper = new LambdaQueryWrapper<>();
        userWrapper.eq(User::getBranch, user.getBranch());
        List<User> branchUsers = userMapper.selectList(userWrapper);
        
        int totalProgress = 0;
        int totalDuration = 0;
        int memberCount = 0;
        
        for (User u : branchUsers) {
            if (u.getRole().equals("member")) { // 只算普通成员
                StudyStats stats = getStudyStats(u.getId());
                totalProgress += stats.getTotalProgress();
                totalDuration += stats.getTotalDuration();
                memberCount++;
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("avgProgress", memberCount > 0 ? totalProgress / memberCount : 0);
        result.put("avgDuration", memberCount > 0 ? totalDuration / memberCount : 0);
        result.put("totalMembers", memberCount);
        result.put("branchName", user.getBranch());
        return result;
    }
}