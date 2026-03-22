package com.example.partyapp.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.entity.Message;
import com.example.partyapp.mapper.MessageMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MessageService {
    private final MessageMapper messageMapper;

    // 获取与某个用户的聊天记录
    public List<Message> getMessages(String currentUserId, String otherUserId) {
        return messageMapper.getChatMessages(currentUserId, otherUserId);
    }

    // 发送消息
    @Transactional
    public boolean sendMessage(String senderId, String recipientId, String content) {
        Message message = new Message();
        message.setSenderId(senderId);
        message.setRecipientId(recipientId);
        message.setContent(content);
        message.setIsRead(false);
        message.setCreatedAt(LocalDateTime.now());
        return messageMapper.insert(message) > 0;
    }
    
    // 标记消息为已读
    @Transactional
    public void markMessagesAsRead(String senderId, String recipientId) {
        messageMapper.markMessagesAsRead(senderId, recipientId);
    }
}
