package com.selimhorri.app.resource;

import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.dto.response.collection.DtoCollectionResponse;
import com.selimhorri.app.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.Arrays;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

public class UserResourceTest {

    private MockMvc mockMvc;

    @Mock
    private UserService userService;

    @InjectMocks
    private UserResource userResource;

    private UserDto userDto;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(userResource).build();
        userDto = new UserDto();
        userDto.setUserId(1);
        userDto.setFirstName("testuser");
    }

    @Test
    void testFindAll() throws Exception {
        when(userService.findAll()).thenReturn(Arrays.asList(userDto));
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isOk());
    }

    @Test
    void testFindById() throws Exception {
        when(userService.findById(1)).thenReturn(userDto);
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk());
    }

    @Test
    void testSave() throws Exception {
        when(userService.save(any(UserDto.class))).thenReturn(userDto);
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void testUpdate() throws Exception {
        when(userService.update(any(UserDto.class))).thenReturn(userDto);
        mockMvc.perform(put("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void testUpdateWithId() throws Exception {
        when(userService.update(eq(1), any(UserDto.class))).thenReturn(userDto);
        mockMvc.perform(put("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"testuser\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void testDeleteById() throws Exception {
        doNothing().when(userService).deleteById(1);
        mockMvc.perform(delete("/api/users/1"))
                .andExpect(status().isOk());
    }

    @Test
    void testFindByUsername() throws Exception {
        when(userService.findByUsername("testuser")).thenReturn(userDto);
        mockMvc.perform(get("/api/users/username/testuser"))
                .andExpect(status().isOk());
    }
}
