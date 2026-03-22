package com.example.partyapp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.partyapp.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper extends BaseMapper<User> {
}