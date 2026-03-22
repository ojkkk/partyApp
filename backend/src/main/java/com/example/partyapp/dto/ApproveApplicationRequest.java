package com.example.partyapp.dto;

import lombok.Data;

@Data
public class ApproveApplicationRequest {
    private String applicationId;
    private boolean approved;
}
