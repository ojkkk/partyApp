package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.TableField;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("dues_payments")
public class DuesPayment {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    
    @TableField("user_id")
    private String userId;
    
    @TableField("payment_month")
    private LocalDate paymentMonth;
    
    private BigDecimal amount;
    
    @TableField("payment_method")
    private String paymentMethod;
    
    @TableField("payment_status")
    private String paymentStatus;
    
    @TableField("payment_date")
    private LocalDateTime paymentDate;
    
    @TableField("created_at")
    private LocalDateTime createdAt;
    
    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
