package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.dto.LoginRequest;
import com.example.partyapp.dto.LoginResponse;
import com.example.partyapp.dto.RegisterRequest;
import com.example.partyapp.entity.User;
import com.example.partyapp.mapper.UserMapper;
import com.example.partyapp.service.DuesService;
import com.example.partyapp.service.BranchService;
import com.example.partyapp.util.JwtUtil;
import cn.hutool.crypto.digest.BCrypt;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Base64;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final DuesService duesService;
    private final BranchService branchService;

    public LoginResponse login(LoginRequest request) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, request.getUsername());
        User user = userMapper.selectOne(wrapper);

        if (user == null || !BCrypt.checkpw(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        
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

        return new LoginResponse(token, userInfo);
    }

    @Transactional
    public User register(RegisterRequest request) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, request.getUsername());
        if (userMapper.selectCount(wrapper) > 0) {
            throw new RuntimeException("用户名已存在");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(BCrypt.hashpw(request.getPassword()));
        user.setName(request.getName());
        user.setRole(request.getRole());
        user.setPartyId(request.getPartyId());
        user.setJoinDate(LocalDate.parse(request.getJoinDate()));
        user.setRegistrationDate(LocalDate.now());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());
        
        // 对于普通党员，branch字段设置为null
        user.setBranch(null);

        userMapper.insert(user);
        
        // 如果是支部管理员，创建支部
        if ("branch_admin".equals(request.getRole()) && request.getBranch() != null && !request.getBranch().isEmpty()) {
            branchService.createBranch(request.getBranch(), user.getId());
            user.setBranch(request.getBranch());
            userMapper.updateById(user);
        }
        
        // 为新用户生成当月的党费记录
        duesService.generateMonthlyDues(user.getId());
        return user;
    }

    public User getUserById(String id) {
        return userMapper.selectById(id);
    }
}