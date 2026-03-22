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
  createdBy?: string;
  createdAt?: string;
  updatedAt?: string;
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
}
