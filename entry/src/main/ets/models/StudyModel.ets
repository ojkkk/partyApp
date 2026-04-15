import { NetworkService } from '../services/NetworkService';
import { ApiResponse } from './UserModel';

export interface StudyResource {
  id: string;
  title: string;
  type: string;
  content: string;
  duration: number;
  imageUrl: string;
  videoUrl?: string;
  parentId?: string;   // 父级ID，NULL=顶级专题目录
  sortOrder?: number;  // 排序序号
  createdBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

/** 专题学习目录（含子资源列表） */
export interface StudyTopic {
  id: string;
  title: string;
  content: string;
  imageUrl?: string;
  createdBy?: string;
  createdAt?: string;
  childCount: number;
  children: StudyResource[];
}

export interface StudyStats {
  totalCourses: number;
  completedCourses: number;
  totalDuration: number;
  totalProgress: number;
}

export interface UserStudyStats {
  userId: string;
  username: string;
  name: string;
  role: string;
  branch: string;
  totalCourses: number;
  completedCourses: number;
  totalDuration: number;
  totalProgress: number;
}

export interface ResourceProgress {
  progress: number;
  studyDuration: number;
}

class StudyParams {
  type: string;

  constructor(type: string) {
    this.type = type;
  }
}

class ProgressParams {
  progress: number;

  constructor(progress: number) {
    this.progress = progress;
  }
}

export class StudyService {
  async getResources(type?: string): Promise<ApiResponse<StudyResource[]>> {
    let params: StudyParams | undefined = undefined;
    if (type) {
      params = new StudyParams(type);
    }
    return await NetworkService.get<ApiResponse<StudyResource[]>>('/api/study/resources', params);
  }

  async getResourceDetail(id: string): Promise<ApiResponse<StudyResource>> {
    return await NetworkService.get<ApiResponse<StudyResource>>(`/api/study/resources/${id}`);
  }

  // ===== 专题目录 API =====

  /** 获取专题目录列表（含子资源） */
  async getTopics(): Promise<ApiResponse<StudyTopic[]>> {
    return await NetworkService.get<ApiResponse<StudyTopic[]>>('/api/study/topics');
  }

  /** 获取某专题下的子资源 */
  async getTopicChildren(topicId: string): Promise<ApiResponse<StudyResource[]>> {
    return await NetworkService.get<ApiResponse<StudyResource[]>>(`/api/study/topics/${topicId}/children`);
  }

  /** 创建专题目录 */
  async createTopic(topic: StudyResource): Promise<ApiResponse<StudyResource>> {
    return await NetworkService.post<ApiResponse<StudyResource>>('/api/study/topics', topic);
  }

  /** 更新专题目录 */
  async updateTopic(id: string, topic: StudyResource): Promise<ApiResponse<StudyResource>> {
    return await NetworkService.put<ApiResponse<StudyResource>>(`/api/study/topics/${id}`, topic);
  }

  /** 删除专题目录（含所有子资源） */
  async deleteTopic(id: string): Promise<ApiResponse<void>> {
    return await NetworkService.delete<ApiResponse<void>>(`/api/study/topics/${id}`);
  }

  // ===== 资源 API =====

  async createResource(resource: StudyResource): Promise<ApiResponse<StudyResource>> {
    return await NetworkService.post<ApiResponse<StudyResource>>('/api/study/resources', resource);
  }

  async updateResource(id: string, resource: StudyResource): Promise<ApiResponse<StudyResource>> {
    return await NetworkService.put<ApiResponse<StudyResource>>(`/api/study/resources/${id}`, resource);
  }

  async deleteResource(id: string): Promise<ApiResponse<void>> {
    return await NetworkService.delete<ApiResponse<void>>(`/api/study/resources/${id}`);
  }

  async updateProgress(id: string, progress: number, duration: number): Promise<ApiResponse<void>> {
    return await NetworkService.put<ApiResponse<void>>(`/api/study/progress/${id}?progress=${progress}&duration=${duration}`);
  }

  async toggleFavorite(id: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.post<ApiResponse<boolean>>(`/api/study/resources/${id}/favorite`);
  }

  async getStudyStats(): Promise<ApiResponse<StudyStats>> {
    return await NetworkService.get<ApiResponse<StudyStats>>('/api/study/stats');
  }

  async getFavorites(): Promise<ApiResponse<StudyResource[]>> {
    return await NetworkService.get<ApiResponse<StudyResource[]>>('/api/study/favorites');
  }

  async getAllUserStudyStats(): Promise<ApiResponse<UserStudyStats[]>> {
    return await NetworkService.get<ApiResponse<UserStudyStats[]>>('/api/study/all-stats');
  }

  async getResourceProgress(id: string): Promise<ApiResponse<ResourceProgress>> {
    return await NetworkService.get<ApiResponse<ResourceProgress>>(`/api/study/progress/${id}`);
  }

  async search(keyword: string): Promise<ApiResponse<StudyResource[]>> {
    return await NetworkService.get<ApiResponse<StudyResource[]>>(`/api/study/resources/search?keyword=${keyword}`);
  }

  /** 获取用户学习状态分布（扇形图数据） */
  async getMyLearningDistribution(): Promise<ApiResponse<LearningDistribution>> {
    return await NetworkService.get<ApiResponse<LearningDistribution>>('/api/study/my-distribution');
  }

  /** 获取支部平均学习进度 */
  async getBranchAverage(): Promise<ApiResponse<BranchAverage>> {
    return await NetworkService.get<ApiResponse<BranchAverage>>('/api/study/branch-average');
  }
}

// 学习状态分布（扇形图数据）
export interface LearningDistribution {
  notStarted: number;   // 未学习
  inProgress: number;   // 正在学习
  completed: number;   // 已完成
  total: number;
}

// 支部平均学习进度
export interface BranchAverage {
  avgProgress: number;
  avgDuration: number;
  totalMembers: number;
  branchName: string;
}
