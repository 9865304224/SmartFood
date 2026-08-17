package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.Complaint;
import com.smartfood.model.enums.ComplaintCategory;
import com.smartfood.model.enums.ComplaintStatus;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.ComplaintService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/complaints")
@RequiredArgsConstructor
public class ComplaintController {

    private final ComplaintService complaintService;

    @Data
    public static class CreateComplaintDto {
        private String orderId;
        private ComplaintCategory category;
        private String description;
    }

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<Complaint>> createComplaint(@AuthenticationPrincipal UserPrincipal user,
                                                                  @RequestBody CreateComplaintDto dto) {
        Complaint complaint = complaintService.createComplaint(user.getId(), dto.getOrderId(), dto.getCategory(), dto.getDescription());
        return ResponseEntity.ok(ApiResponse.success("Complaint registered", complaint));
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<List<Complaint>>> getMyComplaints(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(complaintService.getCustomerComplaints(user.getId())));
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<Complaint>>> getAllComplaints(@RequestParam(required = false) ComplaintStatus status) {
        return ResponseEntity.ok(ApiResponse.success(complaintService.getAllComplaints(status)));
    }

    @Data
    public static class ResolveComplaintDto {
        private ComplaintStatus status;
        private String resolutionDetails;
        private String adminNotes;
    }

    @PostMapping("/{complaintId}/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Complaint>> resolveComplaint(@AuthenticationPrincipal UserPrincipal user,
                                                                   @PathVariable String complaintId,
                                                                   @RequestBody ResolveComplaintDto dto) {
        Complaint resolved = complaintService.resolveComplaint(complaintId, user.getId(), dto.getStatus(), dto.getResolutionDetails(), dto.getAdminNotes());
        return ResponseEntity.ok(ApiResponse.success("Complaint resolved", resolved));
    }
}
