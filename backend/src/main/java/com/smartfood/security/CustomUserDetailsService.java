package com.smartfood.security;

import com.smartfood.model.User;
import com.smartfood.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String usernameOrPhoneOrEmail) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(usernameOrPhoneOrEmail)
                .or(() -> userRepository.findByPhone(usernameOrPhoneOrEmail))
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email or phone: " + usernameOrPhoneOrEmail));

        return UserPrincipal.create(user);
    }

    public UserDetails loadUserById(String id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + id));

        return UserPrincipal.create(user);
    }
}
