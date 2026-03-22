package com.example.partyapp;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.example.partyapp.mapper")
public class PartyAppApplication {
    public static void main(String[] args) {
        SpringApplication.run(PartyAppApplication.class, args);
    }
}