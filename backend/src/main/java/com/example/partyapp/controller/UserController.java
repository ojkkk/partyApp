package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
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
            // 将byte[]类型的avatar转换为字符串
            if (user.getAvatar() != null) {
                this.avatar = new String(user.getAvatar());
            }
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

    // 修改密码
    @PostMapping("/change-password")
    public ApiResponse<Boolean> changePassword(@RequestParam("oldPassword") String oldPassword, 
                                             @RequestParam("newPassword") String newPassword) {
        try {
            String userId = UserContext.getUserId();
            boolean result = userService.changePassword(userId, oldPassword, newPassword);
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
}
