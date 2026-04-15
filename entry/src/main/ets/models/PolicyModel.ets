import { NetworkService } from '../services/NetworkService';
import { ApiResponse } from './UserModel';

export interface Policy {
  id: string;
  title: string;
  content: string;
  type: string;
  publishDate: string;
  imageUrl: string;
  videoUrl?: string;
  summary?: string;
  tags?: string;
  publisher?: string;
  viewCount?: number;
  createdBy?: string;
  createdAt?: string;
  updatedAt?: string;
  isFavorite?: boolean;
}

export interface PolicyComment {
  id: string;
  policyId: string;
  userId: string;
  content: string;
  createdAt: string;
  userName: string;
  userBranch: string;
  userAvatar?: string;
}

export interface CommentRequest {
  content: string;
}

class PolicyParams {
  type: string;

  constructor(type: string) {
    this.type = type;
  }
}

export class PolicyService {
  async getPolicies(type?: string): Promise<ApiResponse<Policy[]>> {
    let params: PolicyParams | undefined = undefined;
    if (type) {
      params = new PolicyParams(type);
    }
    return await NetworkService.get<ApiResponse<Policy[]>>('/api/policies', params);
  }

  async getPolicyDetail(id: string): Promise<ApiResponse<Policy>> {
    return await NetworkService.get<ApiResponse<Policy>>(`/api/policies/${id}`);
  }

  async createPolicy(policy: Policy): Promise<ApiResponse<Policy>> {
    return await NetworkService.post<ApiResponse<Policy>>('/api/policies', policy);
  }

  async updatePolicy(id: string, policy: Policy): Promise<ApiResponse<Policy>> {
    return await NetworkService.put<ApiResponse<Policy>>(`/api/policies/${id}`, policy);
  }

  async deletePolicy(id: string): Promise<ApiResponse<void>> {
    return await NetworkService.delete<ApiResponse<void>>(`/api/policies/${id}`);
  }

  async toggleFavorite(id: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.post<ApiResponse<boolean>>(`/api/policies/${id}/favorite`);
  }

  async getFavorites(): Promise<ApiResponse<Policy[]>> {
    return await NetworkService.get<ApiResponse<Policy[]>>('/api/policies/favorites');
  }

  async search(keyword: string): Promise<ApiResponse<Policy[]>> {
    return await NetworkService.get<ApiResponse<Policy[]>>(`/api/policies/search?keyword=${keyword}`);
  }

  async addComment(policyId: string, content: string): Promise<ApiResponse<PolicyComment>> {
    const request: CommentRequest = { content };
    return await NetworkService.post<ApiResponse<PolicyComment>>(`/api/policies/${policyId}/comments`, request);
  }

  async getComments(policyId: string): Promise<ApiResponse<PolicyComment[]>> {
    return await NetworkService.get<ApiResponse<PolicyComment[]>>(`/api/policies/${policyId}/comments`);
  }
}
