import { NetworkService } from '../services/NetworkService';

export interface UserInfo {
  id: string;
  username: string;
  name: string;
  role: 'admin' | 'branch_admin' | 'member';
  partyId: string;
  branch: string;
  joinDate?: string;
  registrationDate?: string;
  phone?: string;
  email?: string;
  avatar?: string;
  isOnline?: boolean;
  lastSeen?: string;
}

export interface User extends UserInfo {
  password?: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
  name: string;
  role: 'admin' | 'branch_admin' | 'member';
  partyId: string;
  branch: string;
  joinDate: string;
  phone?: string;
  email?: string;
  avatar?: string;
}

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface LoginResponse {
  token: string;
  user: UserInfo;
}

// 党费缴纳相关接口
export interface DuesPayment {
  id: string;
  userId: string;
  paymentMonth: string;
  amount: number;
  paymentMethod?: 'online' | 'offline';
  paymentStatus: 'pending' | 'paid' | 'overdue';
  paymentDate?: string;
  createdAt: string;
  updatedAt: string;
}

export interface DuesStats {
  totalDue: number;
  paidAmount: number;
  overdueAmount: number;
  pendingAmount: number;
  paymentHistory: DuesPayment[];
}

// 请求接口
export interface PayDuesRequest {
  month: string;
  amount: number;
  method: 'online' | 'offline';
}

export interface PayMultipleDuesRequest {
  paymentIds: string[];
  method: 'online' | 'offline';
}

export interface ChangePasswordRequest {
  oldPassword: string;
  newPassword: string;
}

export interface ClearCacheRequest {
  // 空接口
}

export interface AvatarRequest {
  avatar: string;
}

export interface SendMessageRequest {
  recipientId: string;
  content: string;
}

// 响应接口
export interface LoginLog {
  id: number;
  loginTime: string;
  device: string;
  location: string;
}

export interface UpdateInfo {
  version: string;
  latestVersion: string;
  isLatest: boolean;
  updateUrl: string;
}

export interface UserStatus {
  isOnline: boolean;
  lastSeen: string;
}

export interface Message {
  id: string;
  content: string;
  senderId: string;
  recipientId: string;
  createdAt: string;
  isSent?: boolean;
  status?: 'sent' | 'read';
  isRead?: boolean;
}

// 支部相关接口
export interface Branch {
  id: string;
  name: string;
  adminId: string;
  createdAt: string;
  updatedAt: string;
}

export interface BranchApplication {
  id: string;
  userId: string;
  branchId: string;
  status: 'pending' | 'approved' | 'rejected';
  applyDate: string;
  approveDate?: string;
  createdAt: string;
  updatedAt: string;
}

export interface BranchApplicationMessage {
  id: string;
  applicationId: string;
  userId: string;
  type: 'apply' | 'approve' | 'reject';
  content: string;
  isRead: boolean;
  createdAt: string;
}

// 支部相关请求接口
export interface CreateBranchRequest {
  name: string;
}

export interface ApplyForBranchRequest {
  branchId: string;
}

export interface ApproveApplicationRequest {
  applicationId: string;
  approved: boolean;
}

export interface MarkBranchMessageAsReadRequest {
  messageId: string;
}

export class UserService {
  async login(username: string, password: string): Promise<ApiResponse<LoginResponse>> {
    const request: LoginRequest = {
      username,
      password
    };
    return await NetworkService.post<ApiResponse<LoginResponse>>('/api/auth/login', request);
  }

  async register(user: RegisterRequest): Promise<ApiResponse<User>> {
    return await NetworkService.post<ApiResponse<User>>('/api/auth/register', user);
  }

  async getCurrentUser(): Promise<ApiResponse<UserInfo>> {
    return await NetworkService.get<ApiResponse<UserInfo>>('/api/auth/current');
  }

  // 党费相关方法
  async getDuesStats(): Promise<ApiResponse<DuesStats>> {
    return await NetworkService.get<ApiResponse<DuesStats>>('/api/dues/stats');
  }

  async payDues(month: string, amount: number, method: 'online' | 'offline'): Promise<ApiResponse<boolean>> {
    const request: PayDuesRequest = {
      month,
      amount,
      method
    };
    return await NetworkService.post<ApiResponse<boolean>>('/api/dues/pay', request);
  }

  async payMultipleDues(paymentIds: string[], method: 'online' | 'offline'): Promise<ApiResponse<boolean>> {
    const request: PayMultipleDuesRequest = {
      paymentIds,
      method
    };
    return await NetworkService.post<ApiResponse<boolean>>('/api/dues/pay-multiple', request);
  }

  // 用户相关方法
  async getProfile(): Promise<ApiResponse<User>> {
    return await NetworkService.get<ApiResponse<User>>('/api/user/profile');
  }

  async updateProfile(user: Partial<User>): Promise<ApiResponse<User>> {
    return await NetworkService.put<ApiResponse<User>>('/api/user/profile', user);
  }

  async changePassword(oldPassword: string, newPassword: string): Promise<ApiResponse<boolean>> {
    const request: ChangePasswordRequest = {
      oldPassword,
      newPassword
    };
    return await NetworkService.post<ApiResponse<boolean>>('/api/user/change-password', request);
  }

  async getLoginLogs(): Promise<ApiResponse<LoginLog[]>> {
    return await NetworkService.get<ApiResponse<LoginLog[]>>('/api/user/login-logs');
  }

  async clearCache(): Promise<ApiResponse<boolean>> {
    const request: ClearCacheRequest = {};
    return await NetworkService.post<ApiResponse<boolean>>('/api/user/clear-cache', request);
  }

  async checkUpdate(): Promise<ApiResponse<UpdateInfo>> {
    return await NetworkService.get<ApiResponse<UpdateInfo>>('/api/user/check-update');
  }

  async uploadAvatar(avatarUrl: string): Promise<ApiResponse<boolean>> {
    const request: AvatarRequest = { avatar: avatarUrl };
    return await NetworkService.post<ApiResponse<boolean>>('/api/user/avatar', request);
  }

  // 获取党支部成员
  async getBranchMembers(): Promise<ApiResponse<User[]>> {
    return await NetworkService.get<ApiResponse<User[]>>('/api/user/branch-members');
  }

  // 根据ID获取用户信息
  async getUserById(userId: string): Promise<ApiResponse<User>> {
    return await NetworkService.get<ApiResponse<User>>(`/api/user/${userId}`);
  }

  // 获取用户在线状态
  async getUserStatus(userId: string): Promise<ApiResponse<UserStatus>> {
    return await NetworkService.get<ApiResponse<UserStatus>>(`/api/user/${userId}/status`);
  }

  // 获取与某个用户的聊天记录
  async getMessages(userId: string): Promise<ApiResponse<Message[]>> {
    return await NetworkService.get<ApiResponse<Message[]>>(`/api/messages/${userId}`);
  }

  // 发送消息
  async sendMessage(userId: string, content: string): Promise<ApiResponse<boolean>> {
    const request: SendMessageRequest = { recipientId: userId, content };
    return await NetworkService.post<ApiResponse<boolean>>('/api/messages/send', request);
  }

  // 标记聊天消息为已读
  async markChatMessageAsRead(senderId: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.post<ApiResponse<boolean>>(`/api/messages/mark-read/${senderId}`);
  }

  // 搜索用户
  async searchUsers(keyword: string): Promise<ApiResponse<UserInfo[]>> {
    return await NetworkService.get<ApiResponse<UserInfo[]>>(`/api/user/search?keyword=${keyword}`);
  }

  // 支部相关方法
  async getBranches(): Promise<ApiResponse<Branch[]>> {
    return await NetworkService.get<ApiResponse<Branch[]>>('/api/branch/list');
  }

  async createBranch(name: string): Promise<ApiResponse<Branch>> {
    const request: CreateBranchRequest = { name };
    return await NetworkService.post<ApiResponse<Branch>>('/api/branch/create', request);
  }

  async applyForBranch(branchId: string): Promise<ApiResponse<BranchApplication>> {
    const request: ApplyForBranchRequest = { branchId };
    return await NetworkService.post<ApiResponse<BranchApplication>>('/api/branch/apply', request);
  }

  async getPendingApplications(): Promise<ApiResponse<BranchApplication[]>> {
    return await NetworkService.get<ApiResponse<BranchApplication[]>>('/api/branch/pending-applications');
  }

  async approveApplication(applicationId: string, approved: boolean): Promise<ApiResponse<BranchApplication>> {
    const request: ApproveApplicationRequest = { applicationId, approved };
    return await NetworkService.post<ApiResponse<BranchApplication>>('/api/branch/approve', request);
  }

  async getUserApplications(): Promise<ApiResponse<BranchApplication[]>> {
    return await NetworkService.get<ApiResponse<BranchApplication[]>>('/api/branch/applications');
  }

  async getUnreadMessageCount(): Promise<ApiResponse<number>> {
    return await NetworkService.get<ApiResponse<number>>('/api/branch/unread-count');
  }

  async getUserMessages(): Promise<ApiResponse<BranchApplicationMessage[]>> {
    return await NetworkService.get<ApiResponse<BranchApplicationMessage[]>>('/api/branch/messages');
  }

  // 标记支部消息为已读
  async markBranchMessageAsRead(messageId: string): Promise<ApiResponse<boolean>> {
    const request: MarkBranchMessageAsReadRequest = { messageId };
    return await NetworkService.post<ApiResponse<boolean>>('/api/branch/message/read', request);
  }
}