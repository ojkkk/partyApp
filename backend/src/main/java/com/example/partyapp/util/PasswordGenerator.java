package com.example.partyapp.util;

import cn.hutool.crypto.digest.BCrypt;

public class PasswordGenerator {
    public static void main(String[] args) {
        String adminPassword = "admin123";
        String branchPassword = "branch123";
        String memberPassword = "member123";
        
        String adminHash = BCrypt.hashpw(adminPassword);
        String branchHash = BCrypt.hashpw(branchPassword);
        String memberHash = BCrypt.hashpw(memberPassword);
        
        System.out.println("admin123 -> " + adminHash);
        System.out.println("branch123 -> " + branchHash);
        System.out.println("member123 -> " + memberHash);
    }
}
