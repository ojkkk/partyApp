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
import java.util.Random;

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

private static final String[] SUMMARIES = {
        "深入贯彻落实中央决策部署，全面推进各项任务落地见效。",
        "着力加强制度建设和工作创新，确保各项工作取得实效。",
        "坚持问题导向，强化责任担当，推动高质量发展迈上新台阶。",
        "统筹推进重点任务落实，促进各项事业协同发展。",
        "坚持党的全面领导，提升治理效能，服务人民群众。"
    };

    private static final String[] TAGS = {
        "重要文件,需贯彻落实",
        "工作部署,全面推进",
        "制度建设,规范化管理",
        "创新发展,高质量发展",
        "责任落实,监督考核",
        "党的建设,政治建设",
        "改革攻坚,重点突破",
        "民生保障,服务群众"
    };

    public Policy createPolicy(Policy policy) {
        policy.setViewCount(0);
        // publisher 由前端传入，admin 写稿时可不填（显示为空或"待定"）
        Random rand = new Random();
        // 已有 summary/tag 则保留，否则随机分配
        if (policy.getSummary() == null || policy.getSummary().isBlank()) {
            policy.setSummary(SUMMARIES[rand.nextInt(SUMMARIES.length)]);
        }
        if (policy.getTags() == null || policy.getTags().isBlank()) {
            policy.setTags(TAGS[rand.nextInt(TAGS.length)]);
        }
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