package com.example.partyapp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.partyapp.entity.Activity;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ActivityMapper extends BaseMapper<Activity> {
}