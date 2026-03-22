package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.dto.LoginRequest;
import com.example.partyapp.dto.LoginResponse;
import com.example.partyapp.dto.RegisterRequest;
import com.example.partyapp.entity.User;
import com.example.partyapp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.Base64;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            LoginResponse response = authService.login(request);
            return ApiResponse.success(response);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping("/register")
    public ApiResponse<User> register(@Valid @RequestBody RegisterRequest request) {
        try {
            User user = authService.register(request);
            return ApiResponse.success("注册成功", user);
        } catch (Exception e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @GetMapping("/current")
    public ApiResponse<LoginResponse.UserInfo> getCurrentUser() {
        try {
            String userId = UserContext.getUserId();
            User user = authService.getUserById(userId);
            
            // 将byte[]类型的avatar转换为Base64字符串
            String avatarStr = null;
            if (user.getAvatar() != null) {
                avatarStr = Base64.getEncoder().encodeToString(user.getAvatar());
            }

            LoginResponse.UserInfo userInfo = new LoginResponse.UserInfo(
                user.getId(),
                user.getUsername(),
                user.getName(),
                user.getRole(),
                user.getPartyId(),
                user.getBranch(),
                user.getJoinDate() != null ? user.getJoinDate().toString() : null,
                user.getRegistrationDate() != null ? user.getRegistrationDate().toString() : null,
                user.getPhone(),
                user.getEmail(),
                avatarStr
            );
            return ApiResponse.success(userInfo);
        } catch (Exception e) {
            return ApiResponse.error("获取用户信息失败");
        }
    }
}