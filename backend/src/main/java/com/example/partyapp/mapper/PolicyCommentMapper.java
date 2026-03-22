package com.example.partyapp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.partyapp.entity.PolicyComment;
import java.util.List;

public interface PolicyCommentMapper extends BaseMapper<PolicyComment> {
    List<PolicyComment> selectByPolicyId(String policyId);
}
