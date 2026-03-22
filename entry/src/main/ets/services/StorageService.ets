import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const STORE_NAME = 'partyapp_prefs';

export class StorageService {
  private static preferences: preferences.Preferences | null = null;
  private static context: common.UIAbilityContext | null = null;
  private static memoryCache: Map<string, Object> = new Map();

  static init(context: common.UIAbilityContext): void {
    StorageService.context = context;
  }

  private static async getPreferences(): Promise<preferences.Preferences> {
    if (!StorageService.preferences) {
      if (!StorageService.context) {
        throw new Error('StorageService not initialized');
      }
      try {
        StorageService.preferences = await preferences.getPreferences(StorageService.context, STORE_NAME);
      } catch (error) {
        console.error('获取Preferences失败:', error);
        if (error instanceof Error) {
          throw error;
        }
        throw new Error(String(error));
      }
    }
    return StorageService.preferences!;
  }

  static async setItem<T>(key: string, value: T): Promise<void> {
    try {
      const prefs = await StorageService.getPreferences();
      const stringValue = JSON.stringify(value);
      await prefs.put(key, stringValue);
      await prefs.flush();
      StorageService.memoryCache.set(key, value as Object);
    } catch (error) {
      console.error('存储数据失败:', error);
    }
  }

  static getItem<T>(key: string): T | null {
    try {
      if (StorageService.memoryCache.has(key)) {
        return StorageService.memoryCache.get(key) as T;
      }
      return null;
    } catch (error) {
      console.error('获取数据失败:', error);
      return null;
    }
  }

  static async getItemAsync<T>(key: string): Promise<T | null> {
    try {
      const prefs = await StorageService.getPreferences();
      const stringValue = prefs.getSync(key, '') as string;
      if (!stringValue) {
        return null;
      }
      const value = JSON.parse(stringValue) as T;
      StorageService.memoryCache.set(key, value as Object);
      return value;
    } catch (error) {
      console.error('获取数据失败:', error);
      return null;
    }
  }

  static async removeItem(key: string): Promise<void> {
    try {
      const prefs = await StorageService.getPreferences();
      await prefs.delete(key);
      await prefs.flush();
      StorageService.memoryCache.delete(key);
    } catch (error) {
      console.error('删除数据失败:', error);
    }
  }

  static async clear(): Promise<void> {
    try {
      const prefs = await StorageService.getPreferences();
      await prefs.clear();
      await prefs.flush();
      StorageService.memoryCache.clear();
    } catch (error) {
      console.error('清除数据失败:', error);
    }
  }
}
