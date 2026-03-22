import http from '@ohos.net.http';
import { StorageService } from './StorageService';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { BusinessError } from '@ohos.base';
import fileio from '@ohos.fileio';

export class NetworkService {
  private static baseUrl: string = 'http://10.0.2.2:8081';

  private static getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    const token = StorageService.getItem<string>('token');
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  static async get<T>(url: string, params?: Object): Promise<T> {
    try {
      let fullUrl = `${NetworkService.baseUrl}${url}`;
      if (params) {
        const searchParams: string[] = [];
        const paramsObj = params as Record<string, string>;
        if (paramsObj['type']) {
          searchParams.push(`type=${encodeURIComponent(paramsObj['type'])}`);
        }
        if (paramsObj['status']) {
          searchParams.push(`status=${encodeURIComponent(paramsObj['status'])}`);
        }
        if (searchParams.length > 0) {
          fullUrl += `?${searchParams.join('&')}`;
        }
      }

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: NetworkService.getHeaders(),
        expectDataType: http.HttpDataType.STRING
      });

      httpRequest.destroy();

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(response.result as string) as T;
      } else {
        const errMsg = `HTTP error! status: ${response.responseCode}`;
        throw new Error(errMsg);
      }
    } catch (error) {
      console.error('GET请求失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  static async post<T>(url: string, data?: Object): Promise<T> {
    try {
      const fullUrl = `${NetworkService.baseUrl}${url}`;
      console.log('请求URL:', fullUrl);
      console.log('请求数据:', data);

      const httpRequest = http.createHttp();

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: NetworkService.getHeaders(),
        extraData: data ? JSON.stringify(data) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      console.log('响应状态码:', response.responseCode);
      console.log('响应结果:', response.result);

      httpRequest.destroy();

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(response.result as string) as T;
      } else {
        const errMsg = `HTTP error! status: ${response.responseCode}, result: ${response.result}`;
        console.error(errMsg);
        throw new Error(errMsg);
      }
    } catch (error) {
      console.error('POST请求失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  static async put<T>(url: string, data?: Object): Promise<T> {
    try {
      const fullUrl = `${NetworkService.baseUrl}${url}`;
      const httpRequest = http.createHttp();

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.PUT,
        header: NetworkService.getHeaders(),
        extraData: data ? JSON.stringify(data) : undefined,
        expectDataType: http.HttpDataType.STRING
      });

      httpRequest.destroy();

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(response.result as string) as T;
      } else {
        const errMsg = `HTTP error! status: ${response.responseCode}`;
        throw new Error(errMsg);
      }
    } catch (error) {
      console.error('PUT请求失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  static async delete<T>(url: string): Promise<T> {
    try {
      const fullUrl = `${NetworkService.baseUrl}${url}`;
      const httpRequest = http.createHttp();

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.DELETE,
        header: NetworkService.getHeaders(),
        expectDataType: http.HttpDataType.STRING
      });

      httpRequest.destroy();

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(response.result as string) as T;
      } else {
        const errMsg = `HTTP error! status: ${response.responseCode}`;
        throw new Error(errMsg);
      }
    } catch (error) {
      console.error('DELETE请求失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  static async upload<T>(url: string, fileData: ArrayBuffer): Promise<T> {
    try {
      const fullUrl: string = `${NetworkService.baseUrl}${url}`;
      const httpRequest = http.createHttp();

      // 1. 生成 boundary
      const boundaryStr: string = '----HarmonyOSBoundary' + Math.random().toString(36).substring(2);

      // 2. 构建 headers（不使用 delete，直接重新构建）
      const token: string | null = StorageService.getItem<string>('token');
      const headers: Record<string, string> = {};
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
      headers['Content-Type'] = `multipart/form-data; boundary=${boundaryStr}`;

      // 3. 手动构建 multipart/form-data 请求体（严格使用 CRLF：\r\n）
      const prefixStr: string = `--${boundaryStr}\r\n` +
        `Content-Disposition: form-data; name="avatar"; filename="avatar.jpg"\r\n` +
        `Content-Type: image/jpeg\r\n\r\n`;
      const suffixStr: string = `\r\n--${boundaryStr}--\r\n`;

      // 4. 将字符串转换为 Uint8Array（关键修复：用 NetworkService 替代 this）
      const prefixUint8: Uint8Array = NetworkService.stringToUint8Array(prefixStr);
      const fileUint8: Uint8Array = new Uint8Array(fileData);
      const suffixUint8: Uint8Array = NetworkService.stringToUint8Array(suffixStr);

      // 5. 拼接所有部分
      const finalLength: number = prefixUint8.length + fileUint8.length + suffixUint8.length;
      const finalUint8: Uint8Array = new Uint8Array(finalLength);
      finalUint8.set(prefixUint8, 0);
      finalUint8.set(fileUint8, prefixUint8.length);
      finalUint8.set(suffixUint8, prefixUint8.length + fileUint8.length);

      // 6. 发送请求
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: finalUint8.buffer,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      httpRequest.destroy();

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(response.result as string) as T;
      } else {
        const errMsg: string = `HTTP error! status: ${response.responseCode}, result: ${response.result}`;
        console.error(errMsg);
        throw new Error(errMsg);
      }
    } catch (error) {
      console.error('上传失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  /**
   * 辅助方法：字符串转 Uint8Array（ArkTS 兼容）
   */
  private static stringToUint8Array(str: string): Uint8Array {
    const uint8: Uint8Array = new Uint8Array(str.length);
    for (let i: number = 0; i < str.length; i++) {
      uint8[i] = str.charCodeAt(i);
    }
    return uint8;
  }
}