package com.smartfood.repository;

import com.smartfood.model.User;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.UserRole;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    List<User> findByRole(UserRole role);
    List<User> findByRoleAndApprovalStatus(UserRole role, ApprovalStatus approvalStatus);
    long countByRole(UserRole role);
    long countByApprovalStatus(ApprovalStatus approvalStatus);
}
