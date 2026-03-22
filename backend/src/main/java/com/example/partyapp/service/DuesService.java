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
        wrapper.eq(DuesPayment::getUserId, userId);
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
        LambdaQueryWrapper<DuesPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(DuesPayment::getUserId, userId)
               .eq(DuesPayment::getPaymentMonth, month);
        DuesPayment payment = duesMapper.selectOne(wrapper);

        if (payment != null) {
            payment.setPaymentStatus("paid");
            payment.setPaymentMethod(method);
            payment.setPaymentDate(LocalDateTime.now());
            duesMapper.updateById(payment);
            return true;
        }
        return false;
    }

    // 为用户生成当月的党费记录
    @Transactional
    public void generateMonthlyDues(String userId) {
        LocalDate currentMonth = LocalDate.now().withDayOfMonth(1);
        
        LambdaQueryWrapper<DuesPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(DuesPayment::getUserId, userId)
               .eq(DuesPayment::getPaymentMonth, currentMonth);
        if (duesMapper.selectCount(wrapper) == 0) {
            DuesPayment payment = new DuesPayment();
            payment.setUserId(userId);
            payment.setPaymentMonth(currentMonth);
            payment.setAmount(new BigDecimal("10.00")); // 默认每月10元
            payment.setPaymentStatus("overdue"); // 默认欠费状态
            payment.setCreatedAt(LocalDateTime.now());
            payment.setUpdatedAt(LocalDateTime.now());
            duesMapper.insert(payment);
        }
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
