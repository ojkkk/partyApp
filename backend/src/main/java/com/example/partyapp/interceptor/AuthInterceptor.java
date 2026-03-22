package com.example.partyapp.interceptor;

import com.example.partyapp.annotation.RequireRole;
import com.example.partyapp.context.UserContext;
import com.example.partyapp.entity.User;
import com.example.partyapp.enums.Role;
import com.example.partyapp.mapper.UserMapper;
import com.example.partyapp.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.lang.reflect.Method;
import java.util.Arrays;

@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;
    private final UserMapper userMapper;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (!(handler instanceof HandlerMethod)) {
            return true;
        }

        HandlerMethod handlerMethod = (HandlerMethod) handler;
        Method method = handlerMethod.getMethod();

        String requestUri = request.getRequestURI();
        if (requestUri.equals("/api/auth/login") || requestUri.equals("/api/auth/register")) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        if (token == null || token.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":401,\"message\":\"未登录或token无效\"}");
            return false;
        }

        try {
            String userId = jwtUtil.getUserIdFromToken(token);
            String username = jwtUtil.getUsernameFromToken(token);
            
            User user = userMapper.selectById(userId);
            if (user == null) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"code\":401,\"message\":\"用户不存在\"}");
                return false;
            }

            UserContext.setUserId(userId);
            UserContext.setUsername(username);
            UserContext.setRole(user.getRole());

            if (method.isAnnotationPresent(RequireRole.class) || handlerMethod.getBeanType().isAnnotationPresent(RequireRole.class)) {
                RequireRole requireRole = method.getAnnotation(RequireRole.class);
                if (requireRole == null) {
                    requireRole = handlerMethod.getBeanType().getAnnotation(RequireRole.class);
                }

                Role[] requiredRoles = requireRole.value();
                String userRoleCode = user.getRole();
                boolean hasPermission = Arrays.stream(requiredRoles)
                        .anyMatch(role -> role.getCode().equals(userRoleCode));

                if (!hasPermission) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"code\":403,\"message\":\"权限不足\"}");
                    return false;
                }
            }

            return true;
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":401,\"message\":\"token验证失败\"}");
            return false;
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        UserContext.clear();
    }
}
