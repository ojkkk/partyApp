package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.ApplyForBranchRequest;
import com.example.partyapp.dto.CreateBranchRequest;
import com.example.partyapp.dto.ApproveApplicationRequest;
import com.example.partyapp.dto.MarkBranchMessageAsReadRequest;
import com.example.partyapp.entity.Branch;
import com.example.partyapp.entity.BranchApplication;
import com.example.partyapp.entity.BranchApplicationMessage;
import com.example.partyapp.service.BranchService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/branch")
@RequiredArgsConstructor
public class BranchController {
    private final BranchService branchService;

    // 获取所有支部列表
    @GetMapping("/list")
    public ApiResponse<List<Branch>> getAllBranches() {
        try {
            List<Branch> branches = branchService.getAllBranches();
            return ApiResponse.success(branches);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 创建支部
    @PostMapping("/create")
    public ApiResponse<Branch> createBranch(@RequestBody CreateBranchRequest request) {
        try {
            String userId = UserContext.getUserId();
            Branch branch = branchService.createBranch(request.getName(), userId);
            return ApiResponse.success("支部创建成功", branch);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 申请加入支部
    @PostMapping("/apply")
    public ApiResponse<BranchApplication> applyForBranch(@RequestBody ApplyForBranchRequest request) {
        try {
            String userId = UserContext.getUserId();
            BranchApplication application = branchService.applyForBranch(userId, request.getBranchId());
            return ApiResponse.success("申请已提交，请等待审批", application);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取待审批申请
    @GetMapping("/pending-applications")
    public ApiResponse<List<BranchApplication>> getPendingApplications() {
        try {
            String userId = UserContext.getUserId();
            Branch branch = branchService.getBranchByAdminId(userId);
            if (branch == null) {
                return ApiResponse.error("您不是支部管理员");
            }
            List<BranchApplication> applications = branchService.getPendingApplications(branch.getId());
            return ApiResponse.success(applications);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 审批申请
    @PostMapping("/approve")
    public ApiResponse<BranchApplication> approveApplication(@RequestBody ApproveApplicationRequest request) {
        try {
            BranchApplication application = branchService.approveApplication(request.getApplicationId(), request.isApproved());
            return ApiResponse.success(request.isApproved() ? "审批通过" : "审批拒绝", application);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取用户的申请历史
    @GetMapping("/applications")
    public ApiResponse<List<BranchApplication>> getUserApplications() {
        try {
            String userId = UserContext.getUserId();
            List<BranchApplication> applications = branchService.getUserApplications(userId);
            return ApiResponse.success(applications);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取未读消息数
    @GetMapping("/unread-count")
    public ApiResponse<Integer> getUnreadMessageCount() {
        try {
            String userId = UserContext.getUserId();
            int count = branchService.getUnreadMessageCount(userId);
            return ApiResponse.success(count);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取消息列表
    @GetMapping("/messages")
    public ApiResponse<List<BranchApplicationMessage>> getUserMessages() {
        try {
            String userId = UserContext.getUserId();
            List<BranchApplicationMessage> messages = branchService.getUserMessages(userId);
            return ApiResponse.success(messages);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 标记消息为已读
    @PostMapping("/message/read")
    public ApiResponse<Boolean> markMessageAsRead(@RequestBody MarkBranchMessageAsReadRequest request) {
        try {
            branchService.markMessageAsRead(request.getMessageId());
            return ApiResponse.success(true);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }
}
