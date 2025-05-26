package com.selimhorri.app.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;
import com.selimhorri.app.service.CategoryService;
import com.selimhorri.app.service.ProductService;

@SpringBootTest
@ActiveProfiles("dev")
public class ProductServiceIntegrationTest {
    
    @Autowired
    private ProductService productService;
    
    @Autowired
    private CategoryService categoryService;
    
    @Test
    @DisplayName("Test should get all products")
    public void testFindAll() {
        // When
        List<ProductDto> products = productService.findAll();
        
        // Then
        assertThat(products).isNotNull();
        assertThat(products).isNotEmpty();
    }
    
    @Test
    @DisplayName("Test should get product by ID")
    public void testFindById() {
        // Given
        Integer productId = 1;
        
        // When
        ProductDto productDto = productService.findById(productId);
        
        // Then
        assertNotNull(productDto);
        assertEquals(productId, productDto.getProductId());
    }
    
    @Test
    @DisplayName("Test should throw exception for non-existent product ID")
    public void testFindByIdNotFound() {
        // Given
        Integer nonExistentId = 999;
        
        // When & Then
        assertThrows(ProductNotFoundException.class, () -> {
            productService.findById(nonExistentId);
        });
    }
    
    @Test
    @DisplayName("Test should save new product")
    public void testSave() {
        // Given
        CategoryDto categoryDto = categoryService.findById(1);
        
        ProductDto newProductDto = ProductDto.builder()
                .productTitle("Service Test Product")
                .imageUrl("https://example.com/service-test.jpg")
                .sku("SERVICE-TEST-SKU-123")
                .priceUnit(129.99)
                .quantity(25)
                .categoryDto(categoryDto)
                .build();
        
        // When
        ProductDto savedProductDto = productService.save(newProductDto);
        
        // Then
        assertNotNull(savedProductDto.getProductId());
        assertEquals("Service Test Product", savedProductDto.getProductTitle());
    }
    
    @Test
    @DisplayName("Test should update existing product")
    public void testUpdate() {
        // Given
        ProductDto existingProduct = productService.findById(1);
        String updatedTitle = "Updated Service Product";
        existingProduct.setProductTitle(updatedTitle);
        
        // When
        ProductDto updatedProduct = productService.update(existingProduct);
        
        // Then
        assertEquals(updatedTitle, updatedProduct.getProductTitle());
        assertEquals(1, updatedProduct.getProductId());
    }
    
    
    @Test
    @DisplayName("Test should delete product by ID")
    public void testDeleteById() {
        // Given
        // First save a new product to delete
        CategoryDto categoryDto = categoryService.findById(1);
        
        ProductDto productToDelete = ProductDto.builder()
                .productTitle("Product To Delete")
                .imageUrl("https://example.com/delete-test.jpg")
                .sku("DELETE-TEST-SKU-999")
                .priceUnit(9.99)
                .quantity(1)
                .categoryDto(categoryDto)
                .build();
        
        ProductDto savedProduct = productService.save(productToDelete);
        Integer productId = savedProduct.getProductId();
        
        // When
        productService.deleteById(productId);
        
        // Then
        assertThrows(ProductNotFoundException.class, () -> {
            productService.findById(productId);
        });
    }
}
