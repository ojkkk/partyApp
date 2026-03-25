package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.entity.DuesPayment;
import com.example.partyapp.mapper.DuesMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DuesService {
    private final DuesMapper duesMapper;

    // 获取用户的党费统计信息
    public DuesStats getDuesStats(String userId) {
        LambdaQueryWrapper<DuesPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(DuesPayment::getUserId, userId)
               .orderByDesc(DuesPayment::getCreatedAt); // 按生成日期降序排序
        List<DuesPayment> payments = duesMapper.selectList(wrapper);

        BigDecimal totalDue = BigDecimal.ZERO;
        BigDecimal paidAmount = BigDecimal.ZERO;
        BigDecimal overdueAmount = BigDecimal.ZERO;
        BigDecimal pendingAmount = BigDecimal.ZERO;

        for (DuesPayment payment : payments) {
            totalDue = totalDue.add(payment.getAmount());
            switch (payment.getPaymentStatus()) {
                case "paid":
                    paidAmount = paidAmount.add(payment.getAmount());
                    break;
                case "overdue":
                    overdueAmount = overdueAmount.add(payment.getAmount());
                    break;
                case "pending":
                    pendingAmount = pendingAmount.add(payment.getAmount());
                    break;
            }
        }

        return new DuesStats(totalDue, paidAmount, overdueAmount, pendingAmount, payments);
    }

    // 缴纳党费
    @Transactional
    public boolean payDues(String userId, LocalDate month, BigDecimal amount, String method) {
        // 先尝试按日期和金额查询
        LambdaQueryWrapper<DuesPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(DuesPayment::getUserId, userId)
               .eq(DuesPayment::getAmount, amount);
        
        // 尝试按LocalDate查询
        DuesPayment payment = duesMapper.selectOne(wrapper.eq(DuesPayment::getPaymentMonth, month));
        
        // 如果没找到，尝试获取用户的所有待缴党费，然后找到匹配的
        if (payment == null) {
            wrapper.clear();
            wrapper.eq(DuesPayment::getUserId, userId)
                   .eq(DuesPayment::getPaymentStatus, "pending")
                   .eq(DuesPayment::getAmount, amount);
            
            List<DuesPayment> payments = duesMapper.selectList(wrapper);
            for (DuesPayment p : payments) {
                if (p.getPaymentMonth().equals(month)) {
                    payment = p;
                    break;
                }
            }
        }

        if (payment != null) {
            payment.setPaymentStatus("paid");
            payment.setPaymentMethod(method);
            payment.setPaymentDate(LocalDateTime.now());
            payment.setUpdatedAt(LocalDateTime.now());
            duesMapper.updateById(payment);
            return true;
        }
        return false;
    }

    // 为用户生成每日的党费记录
    @Transactional
    public void generateDailyDues(String userId, java.math.BigDecimal duesAmount) {
        LocalDate today = LocalDate.now();
        
        LambdaQueryWrapper<DuesPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(DuesPayment::getUserId, userId)
               .eq(DuesPayment::getPaymentMonth, today);
        if (duesMapper.selectCount(wrapper) == 0) {
            DuesPayment payment = new DuesPayment();
            payment.setUserId(userId);
            payment.setPaymentMonth(today);
            payment.setAmount(duesAmount != null ? duesAmount : new java.math.BigDecimal("0.60")); // 使用用户设置的金额，默认0.6元
            payment.setPaymentStatus("pending"); // 默认待支付状态
            payment.setCreatedAt(LocalDateTime.now());
            payment.setUpdatedAt(LocalDateTime.now());
            duesMapper.insert(payment);
        }
    }
    
    // 为用户生成当月的党费记录（保留旧方法，确保兼容性）
    @Transactional
    public void generateMonthlyDues(String userId) {
        generateDailyDues(userId, new java.math.BigDecimal("0.60"));
    }
    
    // 批量缴纳党费
    @Transactional
    public boolean payMultipleDues(String userId, List<String> paymentIds, String method) {
        for (String paymentId : paymentIds) {
            DuesPayment payment = duesMapper.selectById(paymentId);
            if (payment != null && payment.getUserId().equals(userId)) {
                payment.setPaymentStatus("paid");
                payment.setPaymentMethod(method);
                payment.setPaymentDate(LocalDateTime.now());
                payment.setUpdatedAt(LocalDateTime.now());
                duesMapper.updateById(payment);
            }
        }
        return true;
    }

    // 内部类，用于返回党费统计信息
    public static class DuesStats {
        private final BigDecimal totalDue;
        private final BigDecimal paidAmount;
        private final BigDecimal overdueAmount;
        private final BigDecimal pendingAmount;
        private final List<DuesPayment> paymentHistory;

        public DuesStats(BigDecimal totalDue, BigDecimal paidAmount, BigDecimal overdueAmount, BigDecimal pendingAmount, List<DuesPayment> paymentHistory) {
            this.totalDue = totalDue;
            this.paidAmount = paidAmount;
            this.overdueAmount = overdueAmount;
            this.pendingAmount = pendingAmount;
            this.paymentHistory = paymentHistory;
        }

        public BigDecimal getTotalDue() {
            return totalDue;
        }

        public BigDecimal getPaidAmount() {
            return paidAmount;
        }

        public BigDecimal getOverdueAmount() {
            return overdueAmount;
        }

        public BigDecimal getPendingAmount() {
            return pendingAmount;
        }

        public List<DuesPayment> getPaymentHistory() {
            return paymentHistory;
        }
    }
}
