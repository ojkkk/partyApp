package com.example.partyapp.controller;

import com.example.partyapp.context.UserContext;
import com.example.partyapp.dto.ApiResponse;
import com.example.partyapp.entity.Message;
import com.example.partyapp.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
public class MessageController {
    private final MessageService messageService;

    // 获取与某个用户的聊天记录
    @GetMapping("/{userId}")
    public ApiResponse<List<Message>> getMessages(@PathVariable String userId) {
        try {
            String currentUserId = UserContext.getUserId();
            List<Message> messages = messageService.getMessages(currentUserId, userId);
            return ApiResponse.success(messages);
        } catch (Exception e) {
            return ApiResponse.error("获取消息失败");
        }
    }

    // 发送消息
    @PostMapping("/send")
    public ApiResponse<Boolean> sendMessage(@RequestBody SendMessageRequest request) {
        try {
            String senderId = UserContext.getUserId();
            boolean result = messageService.sendMessage(senderId, request.getRecipientId(), request.getContent());
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error("发送消息失败");
        }
    }
    
    // 标记消息为已读
    @PostMapping("/mark-read/{senderId}")
    public ApiResponse<Boolean> markMessagesAsRead(@PathVariable String senderId) {
        try {
            String recipientId = UserContext.getUserId();
            messageService.markMessagesAsRead(senderId, recipientId);
            return ApiResponse.success(true);
        } catch (Exception e) {
            return ApiResponse.error("标记消息已读失败");
        }
    }

    // 发送消息请求DTO
    private static class SendMessageRequest {
        private String recipientId;
        private String content;

        public String getRecipientId() {
            return recipientId;
        }

        public void setRecipientId(String recipientId) {
            this.recipientId = recipientId;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }
}
