package com.declutter.backend.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableLogic;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * Base Entity
 * Common fields for all entities
 */
@Data
public abstract class BaseEntity implements Serializable {

    /**
     * Creation timestamp
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * Last update timestamp
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    /**
     * Logical delete flag (0: not deleted, 1: deleted)
     */
    @TableLogic
    private Integer deleted;
}
