package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.service.DuesService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/dues")
@RequiredArgsConstructor
public class DuesController {
    private final DuesService duesService;

    // 获取党费统计信息
    @GetMapping("/stats")
    public ApiResponse<DuesService.DuesStats> getDuesStats() {
        try {
            String userId = UserContext.getUserId();
            DuesService.DuesStats stats = duesService.getDuesStats(userId);
            return ApiResponse.success(stats);
        } catch (Exception e) {
            return ApiResponse.error("获取党费统计失败");
        }
    }

    // 缴纳党费
    @PostMapping("/pay")
    public ApiResponse<Boolean> payDues(@RequestParam("month") String month, 
                                       @RequestParam("amount") BigDecimal amount, 
                                       @RequestParam("method") String method) {
        try {
            String userId = UserContext.getUserId();
            LocalDate paymentMonth = LocalDate.parse(month);
            boolean result = duesService.payDues(userId, paymentMonth, amount, method);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error("缴纳党费失败");
        }
    }

    // 生成当月党费记录
    @PostMapping("/generate")
    public ApiResponse<Boolean> generateMonthlyDues() {
        try {
            String userId = UserContext.getUserId();
            duesService.generateMonthlyDues(userId);
            return ApiResponse.success(true);
        } catch (Exception e) {
            return ApiResponse.error("生成党费记录失败");
        }
    }
}
