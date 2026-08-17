package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.FoodCategory;
import com.smartfood.repository.FoodCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final FoodCategoryRepository foodCategoryRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<FoodCategory>>> getCategories() {
        return ResponseEntity.ok(ApiResponse.success(foodCategoryRepository.findByIsActiveTrueOrderByDisplayOrderAsc()));
    }
}
