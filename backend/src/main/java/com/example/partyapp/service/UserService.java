package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.example.partyapp.entity.User;
import com.example.partyapp.entity.BranchApplicationMessage;
import com.example.partyapp.mapper.UserMapper;
import com.example.partyapp.mapper.BranchApplicationMessageMapper;
import cn.hutool.crypto.digest.BCrypt;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserMapper userMapper;
    private final BranchApplicationMessageMapper messageMapper;

    // 获取用户信息
    public User getUserById(String id) {
        return userMapper.selectById(id);
    }

    // 更新用户信息
    @Transactional
    public User updateUser(String id, User userUpdate) {
        User user = userMapper.selectById(id);
        if (user != null) {
            // 只更新允许修改的字段
            if (userUpdate.getName() != null) {
                user.setName(userUpdate.getName());
            }
            if (userUpdate.getPartyId() != null) {
                user.setPartyId(userUpdate.getPartyId());
            }
            if (userUpdate.getPhone() != null) {
                user.setPhone(userUpdate.getPhone());
            }
            if (userUpdate.getEmail() != null) {
                user.setEmail(userUpdate.getEmail());
            }
            if (userUpdate.getJoinDate() != null) {
                user.setJoinDate(userUpdate.getJoinDate());
            }
            if (userUpdate.getAvatar() != null) {
                user.setAvatar(userUpdate.getAvatar());
            }
            user.setUpdatedAt(LocalDateTime.now());
            userMapper.updateById(user);
        }
        return user;
    }

    // 修改密码
    @Transactional
    public boolean changePassword(String id, String oldPassword, String newPassword) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        if (!BCrypt.checkpw(oldPassword, user.getPassword())) {
            throw new RuntimeException("旧密码错误");
        }
        user.setPassword(BCrypt.hashpw(newPassword));
        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        return true;
    }

    // 获取登录日志
    public Object getLoginLogs(String userId) {
        // 这里模拟登录日志数据
        List<Map<String, Object>> logs = new ArrayList<>();
        for (int i = 1; i <= 5; i++) {
            Map<String, Object> log = new HashMap<>();
            log.put("id", i);
            log.put("loginTime", LocalDateTime.now().minusDays(i).toString());
            log.put("device", "设备" + i);
            log.put("location", "位置" + i);
            logs.add(log);
        }
        return logs;
    }

    // 检查更新
    public Object checkUpdate() {
        // 这里模拟更新信息
        Map<String, Object> updateInfo = new HashMap<>();
        updateInfo.put("version", "1.0.0");
        updateInfo.put("latestVersion", "1.0.0");
        updateInfo.put("isLatest", true);
        updateInfo.put("updateUrl", "https://example.com/update");
        return updateInfo;
    }

    // 清理缓存
    public boolean clearCache() {
        // 这里可以实现清理缓存的逻辑
        return true;
    }

    // 更新头像
    @Transactional
    public boolean updateAvatar(String id, String avatarUrl) {
        try {
            User user = userMapper.selectById(id);
            if (user != null) {
                user.setAvatar(avatarUrl);
                user.setUpdatedAt(LocalDateTime.now());
                userMapper.updateById(user);
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new RuntimeException("设置头像失败: " + e.getMessage());
        }
    }

    // 获取党支部成员
    public List<User> getBranchMembers(String userId) {
        User currentUser = userMapper.selectById(userId);
        if (currentUser == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 查询同一党支部的所有成员
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getBranch, currentUser.getBranch());
        return userMapper.selectList(queryWrapper);
    }

    // 踢出支部成员
    @Transactional
    public boolean kickMember(String currentUserId, String targetUserId) {
        User currentUser = userMapper.selectById(currentUserId);
        User targetUser = userMapper.selectById(targetUserId);
        
        if (currentUser == null || targetUser == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 检查权限（只有管理员或支部管理员可以踢人）
        if (!"admin".equals(currentUser.getRole()) && !"branch_admin".equals(currentUser.getRole())) {
            throw new RuntimeException("无权操作");
        }
        
        // 不能踢出自己
        if (currentUserId.equals(targetUserId)) {
            throw new RuntimeException("不能踢出自己");
        }
        
        // 不能踢出其他管理员
        if ("admin".equals(targetUser.getRole()) || "branch_admin".equals(targetUser.getRole())) {
            throw new RuntimeException("不能踢出管理员");
        }
        
        // 清空支部信息（踢出支部）
        targetUser.setBranch(null);
        targetUser.setUpdatedAt(LocalDateTime.now());
        
        // 使用UpdateWrapper强制更新null值
        com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<User> updateWrapper = new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<>();
        updateWrapper.set("branch", null);
        updateWrapper.set("updated_at", LocalDateTime.now());
        updateWrapper.eq("id", targetUserId);
        userMapper.update(null, updateWrapper);
        
        // 发送踢出通知消息
        BranchApplicationMessage message = new BranchApplicationMessage();
        message.setApplicationId(null); // 不需要关联申请ID
        message.setUserId(targetUserId);
        message.setType("kick");
        message.setContent("您已被踢出所在支部");
        message.setIsRead(false);
        messageMapper.insert(message);
        
        return true;
    }

    // 重置成员密码
    @Transactional
    public boolean resetPassword(String currentUserId, String targetUserId) {
        User currentUser = userMapper.selectById(currentUserId);
        User targetUser = userMapper.selectById(targetUserId);
        
        if (currentUser == null || targetUser == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 检查权限（只有管理员或支部管理员可以重置密码）
        if (!"admin".equals(currentUser.getRole()) && !"branch_admin".equals(currentUser.getRole())) {
            throw new RuntimeException("无权操作");
        }
        
        // 重置为默认密码（例如：123456）
        targetUser.setPassword(BCrypt.hashpw("123456"));
        targetUser.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(targetUser);
        
        return true;
    }

    // 更新党费金额
    @Transactional
    public boolean updateDuesAmount(String currentUserId, String targetUserId, java.math.BigDecimal amount) {
        User currentUser = userMapper.selectById(currentUserId);
        User targetUser = userMapper.selectById(targetUserId);
        
        if (currentUser == null || targetUser == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 检查权限（只有管理员或支部管理员可以设置党费金额）
        if (!"admin".equals(currentUser.getRole()) && !"branch_admin".equals(currentUser.getRole())) {
            throw new RuntimeException("无权操作");
        }
        
        // 验证金额
        if (amount == null || amount.compareTo(java.math.BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("党费金额必须大于0");
        }
        
        targetUser.setDuesAmount(amount);
        targetUser.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(targetUser);
        
        return true;
    }
}
