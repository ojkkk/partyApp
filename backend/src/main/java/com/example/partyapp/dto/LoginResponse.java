package com.example.partyapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private UserInfo user;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserInfo {
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
    }
}