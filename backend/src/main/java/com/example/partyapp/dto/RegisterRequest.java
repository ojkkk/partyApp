package com.example.partyapp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank(message = "用户名不能为空")
    private String username;

    @NotBlank(message = "密码不能为空")
    private String password;

    @NotBlank(message = "姓名不能为空")
    private String name;

    private String role;

    @NotBlank(message = "党员编号不能为空")
    private String partyId;

    private String branch;

    @NotBlank(message = "手机号不能为空")
    private String phone;

    @Email(message = "邮箱格式不正确")
    @NotBlank(message = "邮箱不能为空")
    private String email;

    @NotBlank(message = "入党日期不能为空")
    private String joinDate;
}