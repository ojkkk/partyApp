import { NetworkService } from '../services/NetworkService';
import { UserInfo, UserService, Message as UserMessage, ApiResponse } from './UserModel';

// 聊天会话模型
export interface ChatSession {
  id: string;
  userId: string;
  userName: string;
  userAvatar: string;
  lastMessage: UserMessage;
  unreadCount: number;
}

// 会话列表响应接口
export interface SessionsResponse {
  code: number;
  data: ChatSession[];
}

// 标记已读响应接口
export interface MarkReadResponse {
  code: number;
}

// 聊天服务
export class ChatService {
  private userService: UserService = new UserService();

  // 获取聊天会话列表
  async getSessions(): Promise<SessionsResponse> {
    try {
      // 获取党支部成员列表
      const membersResponse = await this.userService.getBranchMembers();
      if (membersResponse.code !== 200 || !membersResponse.data) {
        const response: SessionsResponse = {
          code: membersResponse.code,
          data: []
        };
        return response;
      }

      const members = membersResponse.data;
      const sessions: ChatSession[] = [];

      // 为每个成员获取聊天记录，构建会话
      for (const member of members) {
        const messagesResponse = await this.userService.getMessages(member.id);
        if (messagesResponse.code === 200 && messagesResponse.data && messagesResponse.data.length > 0) {
          const messages = messagesResponse.data;
          const lastMessage = messages[messages.length - 1];
          // 确保isRead字段存在，并且正确计算未读消息数
          const unreadCount = messages.filter(msg => msg.senderId === member.id && !(msg.isRead || false)).length;

          const session: ChatSession = {
            id: member.id,
            userId: member.id,
            userName: member.name,
            userAvatar: member.avatar || '',
            lastMessage: lastMessage,
            unreadCount: unreadCount
          };
          sessions.push(session);
        }
      }

      // 排序：未读消息的聊天排在最上方，然后按最后一条消息时间倒序
      sessions.sort((a, b) => {
        if (a.unreadCount > 0 && b.unreadCount === 0) return -1;
        if (a.unreadCount === 0 && b.unreadCount > 0) return 1;
        const dateA = new Date(a.lastMessage.createdAt).getTime();
        const dateB = new Date(b.lastMessage.createdAt).getTime();
        return dateB - dateA;
      });

      const response: SessionsResponse = {
        code: 200,
        data: sessions
      };
      return response;
    } catch (error) {
      console.error('获取聊天会话失败:', error);
      const response: SessionsResponse = {
        code: 500,
        data: []
      };
      return response;
    }
  }

  // 获取未读消息总数
  async getUnreadCount(): Promise<number> {
    const response = await this.getSessions();
    if (response.code === 200 && response.data) {
      return response.data.reduce((total, session) => total + session.unreadCount, 0);
    }
    return 0;
  }

  // 标记会话为已读
  async markSessionAsRead(sessionId: string): Promise<MarkReadResponse> {
    try {
      const response = await this.userService.markChatMessageAsRead(sessionId);
      const markReadResponse: MarkReadResponse = {
        code: response.code
      };
      return markReadResponse;
    } catch (error) {
      console.error('标记会话为已读失败:', error);
      const markReadResponse: MarkReadResponse = {
        code: 500
      };
      return markReadResponse;
    }
  }
}