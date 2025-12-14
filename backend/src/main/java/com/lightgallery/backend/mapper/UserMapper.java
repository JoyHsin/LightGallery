package com.lightgallery.backend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.lightgallery.backend.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * UserMapper
 * MyBatis-Plus mapper for User entity with custom queries
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

    /**
     * Find user by OAuth provider and provider user ID
     * 
     * @param authProvider OAuth provider (apple, wechat, alipay)
     * @param providerUserId User ID from OAuth provider
     * @return User if found, null otherwise
     */
    @Select("SELECT * FROM users WHERE auth_provider = #{authProvider} " +
            "AND provider_user_id = #{providerUserId} AND deleted = 0")
    User findByProviderAndProviderId(@Param("authProvider") String authProvider,
                                     @Param("providerUserId") String providerUserId);

    /**
     * Find user by email
     * 
     * @param email User email address
     * @return User if found, null otherwise
     */
    @Select("SELECT * FROM users WHERE email = #{email} AND deleted = 0")
    User findByEmail(@Param("email") String email);

    /**
     * Update user's last login timestamp
     * 
     * @param userId User ID
     * @param lastLoginAt Last login timestamp
     * @return Number of rows affected
     */
    @Update("UPDATE users SET last_login_at = #{lastLoginAt}, " +
            "updated_at = NOW() WHERE id = #{userId} AND deleted = 0")
    int updateLastLoginAt(@Param("userId") Long userId,
                         @Param("lastLoginAt") LocalDateTime lastLoginAt);

    /**
     * Check if user exists by provider and provider user ID
     * 
     * @param authProvider OAuth provider
     * @param providerUserId User ID from OAuth provider
     * @return true if user exists, false otherwise
     */
    @Select("SELECT COUNT(*) > 0 FROM users WHERE auth_provider = #{authProvider} " +
            "AND provider_user_id = #{providerUserId} AND deleted = 0")
    boolean existsByProviderAndProviderId(@Param("authProvider") String authProvider,
                                         @Param("providerUserId") String providerUserId);

    /**
     * Soft delete user by ID
     * 
     * @param userId User ID
     * @return Number of rows affected
     */
    @Update("UPDATE users SET deleted = 1, updated_at = NOW() WHERE id = #{userId}")
    int softDeleteById(@Param("userId") Long userId);
}
