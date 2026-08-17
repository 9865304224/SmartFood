package com.smartfood.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.smartfood.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ImageUploadService {

    private final Cloudinary cloudinary;

    @Value("${smartfood.storage.type:CLOUDINARY}")
    private String storageType;

    @Value("${smartfood.storage.upload-dir:uploads}")
    private String uploadDir;

    @Value("${smartfood.storage.cloudinary.cloud-name:smartfood-cloud}")
    private String cloudName;

    public record UploadResult(String url, String publicId, String format, long bytes) {}

    public UploadResult uploadProductImage(MultipartFile file, String subfolder) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Please provide a valid, non-empty image file");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new BadRequestException("Uploaded file must be a valid image format (JPEG, PNG, WEBP)");
        }

        String folderPath = "smartfood/" + (subfolder != null ? subfolder : "products");

        // If Cloudinary credentials are set and not mock
        if ("CLOUDINARY".equalsIgnoreCase(storageType) && !cloudName.equals("smartfood-cloud")) {
            try {
                log.info("Uploading image to Cloudinary folder: {}", folderPath);
                Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                        "folder", folderPath,
                        "resource_type", "image",
                        "overwrite", true
                ));

                String url = (String) uploadResult.get("secure_url");
                String publicId = (String) uploadResult.get("public_id");
                String format = (String) uploadResult.get("format");
                long bytes = ((Number) uploadResult.get("bytes")).longValue();

                log.info("Cloudinary upload successful: url={}, publicId={}", url, publicId);
                return new UploadResult(url, publicId, format, bytes);
            } catch (IOException e) {
                log.error("Cloudinary upload error: ", e);
                throw new BadRequestException("Failed to upload image to Cloudinary: " + e.getMessage());
            }
        }

        // Local & Deterministic Storage Fallback
        try {
            Path targetDir = Paths.get(uploadDir, subfolder != null ? subfolder : "products");
            Files.createDirectories(targetDir);

            String originalName = file.getOriginalFilename();
            String extension = originalName != null && originalName.contains(".") 
                    ? originalName.substring(originalName.lastIndexOf(".")) : ".jpg";
            String filename = UUID.randomUUID() + extension;
            Path filePath = targetDir.resolve(filename);

            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            String mockUrl = "https://res.cloudinary.com/smartfood-demo/image/upload/v1/" + folderPath + "/" + filename;
            log.info("Saved image locally with mock Cloudinary URL: {}", mockUrl);

            return new UploadResult(mockUrl, folderPath + "/" + filename, extension.replace(".", ""), file.getSize());
        } catch (IOException e) {
            log.error("Local storage error: ", e);
            throw new BadRequestException("Failed to save image locally: " + e.getMessage());
        }
    }

    public boolean deleteImage(String publicId) {
        if ("CLOUDINARY".equalsIgnoreCase(storageType) && !cloudName.equals("smartfood-cloud")) {
            try {
                Map result = cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
                return "ok".equals(result.get("result"));
            } catch (IOException e) {
                log.error("Cloudinary deletion error: ", e);
                return false;
            }
        }
        return true;
    }
}
