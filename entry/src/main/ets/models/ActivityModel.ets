import { NetworkService } from '../services/NetworkService';
import { ApiResponse } from './UserModel';

export interface Activity {
  id: string;
  title: string;
  content: string;
  startTime: string;
  endTime: string;
  location: string;
  organizer: string;
  imageUrl: string;
  status: 'upcoming' | 'ongoing' | 'completed';
  participantCount: number;
  maxParticipants: number;
  summary?: string;
  summaryImageUrl?: string;
  createdBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface ActivityParticipant {
  registrationId: string;
  userId: string;
  isCheckedIn: boolean;
  checkInTime?: string;
  registeredAt: string;
  username?: string;
  name?: string;
  phone?: string;
  branch?: string;
}

export interface ActivityCreate {
  title: string;
  content: string;
  startTime: string;
  endTime: string;
  location: string;
  organizer: string;
  imageUrl?: string;
  status: 'upcoming' | 'ongoing' | 'completed';
  maxParticipants: number;
}

class ActivityParams {
  status: string;

  constructor(status: string) {
    this.status = status;
  }
}

class SummaryParams {
  summary: string;
  summaryImageUrl?: string;

  constructor(summary: string) {
    this.summary = summary;
  }
}

export class ActivityService {
  async getActivities(status?: string): Promise<ApiResponse<Activity[]>> {
    let params: ActivityParams | undefined = undefined;
    if (status) {
      params = new ActivityParams(status);
    }
    return await NetworkService.get<ApiResponse<Activity[]>>('/api/activities', params);
  }

  async getMyActivities(): Promise<ApiResponse<Activity[]>> {
    return await NetworkService.get<ApiResponse<Activity[]>>('/api/activities/my');
  }

  async getActivityDetail(id: string): Promise<ApiResponse<Activity>> {
    return await NetworkService.get<ApiResponse<Activity>>(`/api/activities/${id}`);
  }

  async createActivity(activity: ActivityCreate): Promise<ApiResponse<Activity>> {
    return await NetworkService.post<ApiResponse<Activity>>('/api/activities', activity);
  }

  async updateActivity(id: string, activity: Activity): Promise<ApiResponse<Activity>> {
    return await NetworkService.put<ApiResponse<Activity>>(`/api/activities/${id}`, activity);
  }

  async deleteActivity(id: string): Promise<ApiResponse<void>> {
    return await NetworkService.delete<ApiResponse<void>>(`/api/activities/${id}`);
  }

  async registerActivity(id: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.post<ApiResponse<boolean>>(`/api/activities/${id}/register`);
  }

  async cancelRegistration(id: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.delete<ApiResponse<boolean>>(`/api/activities/${id}/register`);
  }

  async checkIn(id: string): Promise<ApiResponse<boolean>> {
    return await NetworkService.post<ApiResponse<boolean>>(`/api/activities/${id}/checkin`);
  }

  async uploadSummary(id: string, summary: string, summaryImageUrl?: string): Promise<ApiResponse<boolean>> {
    const params = new SummaryParams(summary);
    if (summaryImageUrl) {
      params.summaryImageUrl = summaryImageUrl;
    }
    return await NetworkService.put<ApiResponse<boolean>>(`/api/activities/${id}/summary`, params);
  }

  async search(keyword: string): Promise<ApiResponse<Activity[]>> {
    return await NetworkService.get<ApiResponse<Activity[]>>(`/api/activities/search?keyword=${keyword}`);
  }

  async getActivityParticipants(id: string): Promise<ApiResponse<ActivityParticipant[]>> {
    return await NetworkService.get<ApiResponse<ActivityParticipant[]>>(`/api/activities/${id}/participants`);
  }
}
