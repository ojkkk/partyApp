package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.ChangePasswordRequest;
import com.example.partyapp.entity.User;
import com.example.partyapp.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    // 用户信息DTO，用于返回给前端
    private static class UserDTO {
        private String id;
        private String username;
        private String name;
        private String role;
        private String partyId;
        private String branch;
        private String joinDate;
        private String registrationDate;
        private String phone;
        private String email;
        private String avatar;

        public UserDTO(User user) {
            this.id = user.getId();
            this.username = user.getUsername();
            this.name = user.getName();
            this.role = user.getRole();
            this.partyId = user.getPartyId();
            this.branch = user.getBranch();
            this.joinDate = user.getJoinDate() != null ? user.getJoinDate().toString() : null;
            this.registrationDate = user.getRegistrationDate() != null ? user.getRegistrationDate().toString() : null;
            this.phone = user.getPhone();
            this.email = user.getEmail();
            this.avatar = user.getAvatar();
        }

        // Getters and setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        public String getPartyId() { return partyId; }
        public void setPartyId(String partyId) { this.partyId = partyId; }
        public String getBranch() { return branch; }
        public void setBranch(String branch) { this.branch = branch; }
        public String getJoinDate() { return joinDate; }
        public void setJoinDate(String joinDate) { this.joinDate = joinDate; }
        public String getRegistrationDate() { return registrationDate; }
        public void setRegistrationDate(String registrationDate) { this.registrationDate = registrationDate; }
        public String getPhone() { return phone; }
        public void setPhone(String phone) { this.phone = phone; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getAvatar() { return avatar; }
        public void setAvatar(String avatar) { this.avatar = avatar; }
    }

    // 获取用户详细信息
    @GetMapping("/profile")
    public ApiResponse<UserDTO> getProfile() {
        try {
            String userId = UserContext.getUserId();
            User user = userService.getUserById(userId);
            UserDTO userDTO = new UserDTO(user);
            return ApiResponse.success(userDTO);
        } catch (Exception e) {
            return ApiResponse.error("获取用户信息失败");
        }
    }

    // 更新用户信息
    @PutMapping("/profile")
    public ApiResponse<UserDTO> updateProfile(@RequestBody User userUpdate) {
        try {
            String userId = UserContext.getUserId();
            User user = userService.updateUser(userId, userUpdate);
            UserDTO userDTO = new UserDTO(user);
            return ApiResponse.success("更新成功", userDTO);
        } catch (Exception e) {
            return ApiResponse.error("更新失败");
        }
    }

    // 管理员更新其他用户信息
    @PutMapping("/update/{userId}")
    public ApiResponse<User> updateUser(@PathVariable String userId, @RequestBody User userUpdate) {
        try {
            String currentUserId = UserContext.getUserId();
            User currentUser = userService.getUserById(currentUserId);
            
            // 检查权限（只有管理员或支部管理员可以更新其他用户信息）
            if (!"admin".equals(currentUser.getRole()) && !"branch_admin".equals(currentUser.getRole())) {
                return ApiResponse.error("无权操作");
            }
            
            User user = userService.updateUser(userId, userUpdate);
            return ApiResponse.success(user);
        } catch (Exception e) {
            return ApiResponse.error("更新失败");
        }
    }

    // 修改密码
    @PostMapping("/change-password")
    public ApiResponse<Boolean> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            String userId = UserContext.getUserId();
            boolean result = userService.changePassword(userId, request.getOldPassword(), request.getNewPassword());
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取登录日志
    @GetMapping("/login-logs")
    public ApiResponse<Object> getLoginLogs() {
        try {
            String userId = UserContext.getUserId();
            Object logs = userService.getLoginLogs(userId);
            return ApiResponse.success(logs);
        } catch (Exception e) {
            return ApiResponse.error("获取登录日志失败");
        }
    }

    // 清理缓存
    @PostMapping("/clear-cache")
    public ApiResponse<Boolean> clearCache() {
        try {
            // 这里可以实现清理用户缓存的逻辑
            return ApiResponse.success(true);
        } catch (Exception e) {
            return ApiResponse.error("清理缓存失败");
        }
    }

    // 检查更新
    @GetMapping("/check-update")
    public ApiResponse<Object> checkUpdate() {
        try {
            // 这里可以实现检查更新的逻辑
            Object updateInfo = userService.checkUpdate();
            return ApiResponse.success(updateInfo);
        } catch (Exception e) {
            return ApiResponse.error("检查更新失败");
        }
    }

    // 上传头像
    @PostMapping("/avatar")
    public ApiResponse<Boolean> uploadAvatar(@RequestBody AvatarRequest avatarRequest) {
        try {
            String userId = UserContext.getUserId();
            boolean result = userService.updateAvatar(userId, avatarRequest.getAvatar());
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 获取党支部成员
    @GetMapping("/branch-members")
    public ApiResponse<List<User>> getBranchMembers() {
        try {
            String userId = UserContext.getUserId();
            List<User> members = userService.getBranchMembers(userId);
            return ApiResponse.success(members);
        } catch (Exception e) {
            return ApiResponse.error("获取党支部成员失败");
        }
    }

    // 根据ID获取用户信息
    @GetMapping("/{userId}")
    public ApiResponse<User> getUserById(@PathVariable String userId) {
        try {
            User user = userService.getUserById(userId);
            return ApiResponse.success(user);
        } catch (Exception e) {
            return ApiResponse.error("获取用户信息失败");
        }
    }

    // 头像请求DTO
    private static class AvatarRequest {
        private String avatar;

        public String getAvatar() {
            return avatar;
        }

        public void setAvatar(String avatar) {
            this.avatar = avatar;
        }
    }

    // 踢出支部成员
    @PostMapping("/kick/{userId}")
    public ApiResponse<Boolean> kickMember(@PathVariable String userId) {
        try {
            String currentUserId = UserContext.getUserId();
            boolean result = userService.kickMember(currentUserId, userId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 重置成员密码
    @PostMapping("/reset-password/{userId}")
    public ApiResponse<Boolean> resetPassword(@PathVariable String userId) {
        try {
            String currentUserId = UserContext.getUserId();
            boolean result = userService.resetPassword(currentUserId, userId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 更新党费金额
    @PutMapping("/dues-amount/{userId}")
    public ApiResponse<Boolean> updateDuesAmount(@PathVariable String userId, @RequestBody DuesAmountRequest request) {
        try {
            String currentUserId = UserContext.getUserId();
            boolean result = userService.updateDuesAmount(currentUserId, userId, request.getAmount());
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    // 党费金额请求DTO
    private static class DuesAmountRequest {
        private java.math.BigDecimal amount;

        public java.math.BigDecimal getAmount() {
            return amount;
        }

        public void setAmount(java.math.BigDecimal amount) {
            this.amount = amount;
        }
    }
}
