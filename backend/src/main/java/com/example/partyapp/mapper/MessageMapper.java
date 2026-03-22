package com.example.partyapp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.partyapp.entity.Message;
import org.apache.ibatis.annotations.Param;
import java.util.List;

public interface MessageMapper extends BaseMapper<Message> {
    // 获取两个用户之间的聊天记录
    List<Message> getChatMessages(@Param("userId1") String userId1, @Param("userId2") String userId2);
    
    // 更新消息为已读状态
    void markMessagesAsRead(@Param("senderId") String senderId, @Param("recipientId") String recipientId);
}
