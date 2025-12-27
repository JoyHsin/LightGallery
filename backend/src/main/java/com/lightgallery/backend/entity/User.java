package com.declutter.backend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * User Entity
 * Represents user account information from OAuth providers
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("users")
public class User extends BaseEntity {

    /**
     * User ID (Primary Key)
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * User display name
     */
    @TableField("display_name")
    private String displayName;

    /**
     * User email address
     */
    @TableField("email")
    private String email;

    /**
     * User avatar URL
     */
    @TableField("avatar_url")
    private String avatarUrl;

    /**
     * OAuth provider: apple, wechat, alipay
     */
    @TableField("auth_provider")
    private String authProvider;

    /**
     * User ID from OAuth provider
     */
    @TableField("provider_user_id")
    private String providerUserId;

    /**
     * Last login timestamp
     */
    @TableField("last_login_at")
    private LocalDateTime lastLoginAt;
}
