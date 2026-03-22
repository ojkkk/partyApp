package com.example.partyapp.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.partyapp.entity.Activity;
import com.example.partyapp.mapper.ActivityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {
    private final ActivityMapper activityMapper;

    @Override
    public void run(String... args) {
        System.out.println("Initializing activity data...");
        
        LambdaQueryWrapper<Activity> wrapper = new LambdaQueryWrapper<>();
        wrapper.isNull(Activity::getCreatedBy);
        long count = activityMapper.selectCount(wrapper);
        
        if (count > 0) {
            System.out.println("Found " + count + " activities without created_by, updating...");
            
            Activity updateActivity = new Activity();
            updateActivity.setCreatedBy("1");
            
            LambdaQueryWrapper<Activity> updateWrapper = new LambdaQueryWrapper<>();
            updateWrapper.isNull(Activity::getCreatedBy);
            activityMapper.update(updateActivity, updateWrapper);
            
            System.out.println("Updated " + count + " activities");
        } else {
            System.out.println("All activities have created_by set");
        }
    }
}
