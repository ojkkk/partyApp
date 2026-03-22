package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.example.partyapp.entity.Branch;
import com.example.partyapp.entity.BranchApplication;
import com.example.partyapp.entity.BranchApplicationMessage;
import com.example.partyapp.entity.User;
import com.example.partyapp.mapper.BranchMapper;
import com.example.partyapp.mapper.BranchApplicationMapper;
import com.example.partyapp.mapper.BranchApplicationMessageMapper;
import com.example.partyapp.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BranchService {
    private final BranchMapper branchMapper;
    private final BranchApplicationMapper branchApplicationMapper;
    private final BranchApplicationMessageMapper messageMapper;
    private final UserMapper userMapper;

    // 创建支部
    @Transactional
    public Branch createBranch(String name, String adminId) {
        // 检查支部名称是否已存在
        LambdaQueryWrapper<Branch> branchWrapper = new LambdaQueryWrapper<>();
        branchWrapper.eq(Branch::getName, name);
        if (branchMapper.selectCount(branchWrapper) > 0) {
            throw new RuntimeException("支部名称已存在");
        }

        Branch branch = new Branch();
        branch.setName(name);
        branch.setAdminId(adminId);
        branchMapper.insert(branch);
        return branch;
    }

    // 获取所有支部列表
    public List<Branch> getAllBranches() {
        return branchMapper.selectList(null);
    }

    // 根据ID获取支部
    public Branch getBranchById(String id) {
        return branchMapper.selectById(id);
    }

    // 根据管理员ID获取支部
    public Branch getBranchByAdminId(String adminId) {
        LambdaQueryWrapper<Branch> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Branch::getAdminId, adminId);
        return branchMapper.selectOne(wrapper);
    }

    // 申请加入支部
    @Transactional
    public BranchApplication applyForBranch(String userId, String branchId) {
        // 检查是否已经申请过
        LambdaQueryWrapper<BranchApplication> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BranchApplication::getUserId, userId)
               .eq(BranchApplication::getBranchId, branchId);
        if (branchApplicationMapper.selectCount(wrapper) > 0) {
            throw new RuntimeException("您已经申请过该支部");
        }

        // 检查用户是否已经属于其他支部
        User user = userMapper.selectById(userId);
        if (user.getBranch() != null && !user.getBranch().isEmpty()) {
            throw new RuntimeException("您已经属于其他支部");
        }

        BranchApplication application = new BranchApplication();
        application.setUserId(userId);
        application.setBranchId(branchId);
        application.setStatus("pending");
        application.setApplyDate(LocalDateTime.now());
        branchApplicationMapper.insert(application);

        // 创建申请消息
        Branch branch = branchMapper.selectById(branchId);
        BranchApplicationMessage message = new BranchApplicationMessage();
        message.setApplicationId(application.getId());
        message.setUserId(branch.getAdminId());
        message.setType("apply");
        message.setContent(user.getName() + " 申请加入 " + branch.getName());
        message.setIsRead(false);
        messageMapper.insert(message);

        return application;
    }

    // 获取支部的待审批申请
    public List<BranchApplication> getPendingApplications(String branchId) {
        LambdaQueryWrapper<BranchApplication> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BranchApplication::getBranchId, branchId)
               .eq(BranchApplication::getStatus, "pending");
        return branchApplicationMapper.selectList(wrapper);
    }

    // 审批申请
    @Transactional
    public BranchApplication approveApplication(String applicationId, boolean approved) {
        BranchApplication application = branchApplicationMapper.selectById(applicationId);
        if (application == null) {
            throw new RuntimeException("申请不存在");
        }

        if (!"pending".equals(application.getStatus())) {
            throw new RuntimeException("该申请已经处理过");
        }

        // 更新申请状态
        LambdaUpdateWrapper<BranchApplication> updateWrapper = new LambdaUpdateWrapper<>();
        updateWrapper.eq(BranchApplication::getId, applicationId)
                     .set(BranchApplication::getStatus, approved ? "approved" : "rejected")
                     .set(BranchApplication::getApproveDate, LocalDateTime.now());
        branchApplicationMapper.update(null, updateWrapper);

        // 如果批准，更新用户的支部信息
        if (approved) {
            LambdaUpdateWrapper<User> userUpdateWrapper = new LambdaUpdateWrapper<>();
            userUpdateWrapper.eq(User::getId, application.getUserId())
                            .set(User::getBranch, branchMapper.selectById(application.getBranchId()).getName());
            userMapper.update(null, userUpdateWrapper);
        }

        // 创建审批消息
        User user = userMapper.selectById(application.getUserId());
        Branch branch = branchMapper.selectById(application.getBranchId());
        BranchApplicationMessage message = new BranchApplicationMessage();
        message.setApplicationId(application.getId());
        message.setUserId(application.getUserId());
        message.setType(approved ? "approve" : "reject");
        message.setContent(approved ? "您的申请已通过，已加入 " + branch.getName() : "您的申请未通过");
        message.setIsRead(false);
        messageMapper.insert(message);

        return branchApplicationMapper.selectById(applicationId);
    }

    // 获取用户的申请历史
    public List<BranchApplication> getUserApplications(String userId) {
        LambdaQueryWrapper<BranchApplication> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BranchApplication::getUserId, userId);
        return branchApplicationMapper.selectList(wrapper);
    }

    // 获取用户的未读消息数
    public int getUnreadMessageCount(String userId) {
        LambdaQueryWrapper<BranchApplicationMessage> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BranchApplicationMessage::getUserId, userId)
               .eq(BranchApplicationMessage::getIsRead, false);
        return messageMapper.selectCount(wrapper).intValue();
    }

    // 获取用户的消息列表
    public List<BranchApplicationMessage> getUserMessages(String userId) {
        LambdaQueryWrapper<BranchApplicationMessage> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BranchApplicationMessage::getUserId, userId)
               .orderByDesc(BranchApplicationMessage::getCreatedAt);
        return messageMapper.selectList(wrapper);
    }

    // 标记消息为已读
    public void markMessageAsRead(String messageId) {
        LambdaUpdateWrapper<BranchApplicationMessage> wrapper = new LambdaUpdateWrapper<>();
        wrapper.eq(BranchApplicationMessage::getId, messageId)
               .set(BranchApplicationMessage::getIsRead, true);
        messageMapper.update(null, wrapper);
    }
}
