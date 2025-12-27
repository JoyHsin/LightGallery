package com.declutter.backend.service;

import com.declutter.backend.entity.User;
import com.declutter.backend.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;

/**
 * Custom UserDetailsService implementation
 * Loads user details for Spring Security authentication
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserMapper userMapper;

    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        log.debug("Loading user by ID: {}", userId);
        
        User user = userMapper.selectById(Long.parseLong(userId));
        
        if (user == null) {
            log.error("User not found with ID: {}", userId);
            throw new UsernameNotFoundException("User not found with ID: " + userId);
        }
        
        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getId().toString())
                .password("") // No password needed for OAuth users
                .authorities(Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")))
                .accountExpired(false)
                .accountLocked(false)
                .credentialsExpired(false)
                .disabled(false)
                .build();
    }
}
