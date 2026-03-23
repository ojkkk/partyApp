package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.entity.Policy;
import com.example.partyapp.entity.PolicyFavorite;
import com.example.partyapp.entity.PolicyComment;
import com.example.partyapp.entity.User;
import com.example.partyapp.dto.PolicyCommentDTO;
import com.example.partyapp.mapper.PolicyFavoriteMapper;
import com.example.partyapp.mapper.PolicyMapper;
import com.example.partyapp.mapper.PolicyCommentMapper;
import com.example.partyapp.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PolicyService {
    private final PolicyMapper policyMapper;
    private final PolicyFavoriteMapper policyFavoriteMapper;
    private final PolicyCommentMapper policyCommentMapper;
    private final UserMapper userMapper;

    public List<Policy> getPolicies(String type) {
        LambdaQueryWrapper<Policy> wrapper = new LambdaQueryWrapper<>();
        if (type != null && !type.equals("全部")) {
            wrapper.eq(Policy::getType, type);
        }
        wrapper.orderByDesc(Policy::getPublishDate);
        return policyMapper.selectList(wrapper);
    }

    public Policy getPolicyDetail(String id) {
        Policy policy = policyMapper.selectById(id);
        if (policy != null) {
            policy.setViewCount(policy.getViewCount() + 1);
            policyMapper.updateById(policy);
        }
        return policy;
    }

    public Policy createPolicy(Policy policy) {
        policy.setViewCount(0);
        policyMapper.insert(policy);
        return policy;
    }

    public Policy updatePolicy(String id, Policy policy) {
        policy.setId(id);
        policyMapper.updateById(policy);
        return policy;
    }

    public void deletePolicy(String id) {
        policyMapper.deleteById(id);
    }

    @Transactional
    public boolean toggleFavorite(String userId, String policyId) {
        LambdaQueryWrapper<PolicyFavorite> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PolicyFavorite::getUserId, userId)
               .eq(PolicyFavorite::getPolicyId, policyId);
        PolicyFavorite favorite = policyFavoriteMapper.selectOne(wrapper);

        if (favorite != null) {
            policyFavoriteMapper.deleteById(favorite.getId());
            return false;
        } else {
            favorite = new PolicyFavorite();
            favorite.setUserId(userId);
            favorite.setPolicyId(policyId);
            policyFavoriteMapper.insert(favorite);
            return true;
        }
    }

    public List<Policy> getFavorites(String userId) {
        LambdaQueryWrapper<PolicyFavorite> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PolicyFavorite::getUserId, userId);
        List<PolicyFavorite> favorites = policyFavoriteMapper.selectList(wrapper);
        
        List<String> policyIds = favorites.stream().map(PolicyFavorite::getPolicyId).toList();
        if (policyIds.isEmpty()) {
            return List.of();
        }
        
        return policyMapper.selectBatchIds(policyIds);
    }

    public PolicyCommentDTO addComment(String userId, String policyId, String content) {
        PolicyComment comment = new PolicyComment();
        comment.setPolicyId(policyId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setCreatedAt(java.time.LocalDateTime.now());
        policyCommentMapper.insert(comment);
        
        User user = userMapper.selectById(userId);
        String userName = user != null ? user.getName() : "未知用户";
        String userBranch = user != null ? user.getBranch() : "未知支部";
        String userAvatar = user != null ? user.getAvatar() : null;
        System.out.println("用户头像: " + userAvatar);
        return new PolicyCommentDTO(comment, userName, userBranch, userAvatar);
    }

    public List<PolicyCommentDTO> getComments(String policyId) {
        LambdaQueryWrapper<PolicyComment> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PolicyComment::getPolicyId, policyId);
        wrapper.orderByDesc(PolicyComment::getCreatedAt);
        List<PolicyComment> comments = policyCommentMapper.selectList(wrapper);
        
        return comments.stream().map(comment -> {
            User user = userMapper.selectById(comment.getUserId());
            String userName = user != null ? user.getName() : "未知用户";
            String userBranch = user != null ? user.getBranch() : "未知支部";
            String userAvatar = user != null ? user.getAvatar() : null;
            System.out.println("评论用户头像: " + userAvatar);
            return new PolicyCommentDTO(comment, userName, userBranch, userAvatar);
        }).toList();
    }
}