package com.smartfood.repository;

import com.smartfood.model.FoodCategory;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FoodCategoryRepository extends MongoRepository<FoodCategory, String> {
    Optional<FoodCategory> findByName(String name);
    List<FoodCategory> findByIsActiveTrueOrderByDisplayOrderAsc();
}
