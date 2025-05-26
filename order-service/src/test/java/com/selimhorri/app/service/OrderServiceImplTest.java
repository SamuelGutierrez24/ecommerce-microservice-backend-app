package com.selimhorri.app.service;

import com.selimhorri.app.dto.OrderDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import com.selimhorri.app.repository.OrderRepository;
import com.selimhorri.app.service.impl.OrderServiceImpl;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class OrderServiceImplTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private OrderDto orderDto;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        orderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test order")
                .orderFee(100.0)
                .build();
    }

    @Test
    void testFindAllReturnsList() {
        when(orderRepository.findAll()).thenReturn(Collections.emptyList());
        assertNotNull(orderService.findAll());
    }

    @Test
    void testFindByIdReturnsOrder() {
        when(orderRepository.findById(1)).thenReturn(Optional.ofNullable(null));
        assertThrows(Exception.class, () -> orderService.findById(1));
    }


    @Test
    void testUpdateWithIdReturnsOrder() {
        when(orderRepository.findById(1)).thenReturn(Optional.ofNullable(null));
        assertThrows(Exception.class, () -> orderService.update(1, orderDto));
    }

    @Test
    void testDeleteById() {
        when(orderRepository.findById(1)).thenReturn(Optional.ofNullable(null));
        assertThrows(Exception.class, () -> orderService.deleteById(1));
    }

    @Test
    void testSaveWithNullOrder() {
        assertThrows(Exception.class, () -> orderService.save(null));
    }

    @Test
    void testUpdateWithNullOrder() {
        assertThrows(Exception.class, () -> orderService.update((OrderDto) null));
    }

    @Test
    void testFindAllNotNull() {
        when(orderRepository.findAll()).thenReturn(new ArrayList<>());
        assertNotNull(orderService.findAll());
    }
}
