package com.example.partyapp.controller;

import com.example.partyapp.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
public class FileController {

    @Value("${file.upload.path:./uploads}")
    private String uploadPath;

    @PostMapping("/upload")
    public ApiResponse<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty()) {
                return ApiResponse.error("文件不能为空");
            }

            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ApiResponse.error("只支持图片文件");
            }

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }

            String datePath = new SimpleDateFormat("yyyy/MM/dd").format(new Date());
            String newFilename = UUID.randomUUID().toString() + extension;

            Path fullPath = Paths.get(uploadPath, datePath);
            if (!Files.exists(fullPath)) {
                Files.createDirectories(fullPath);
            }

            Path filePath = fullPath.resolve(newFilename);
            Files.copy(file.getInputStream(), filePath);

            String fileUrl = "/uploads/" + datePath + "/" + newFilename;
            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("filename", newFilename);

            return ApiResponse.success("上传成功", result);
        } catch (IOException e) {
            return ApiResponse.error("上传失败: " + e.getMessage());
        }
    }
}
