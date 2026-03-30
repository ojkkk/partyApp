package com.example.partyapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudyStats {
    private Integer totalCourses;
    private Integer completedCourses;
    private Integer totalDuration;
    private Integer totalProgress;
}