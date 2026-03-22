package com.example.partyapp.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("branch_applications")
public class BranchApplication {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String userId;

    private String branchId;

    private String status;

    private LocalDateTime applyDate;

    private LocalDateTime approveDate;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
