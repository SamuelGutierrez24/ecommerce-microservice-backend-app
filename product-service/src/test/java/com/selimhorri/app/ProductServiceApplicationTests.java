package com.selimhorri.app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@ActiveProfiles("dev")
class ProductServiceApplicationTests {
	
	@Autowired
	private ApplicationContext applicationContext;
	
	@Test
	void contextLoads() {
		assertNotNull(applicationContext, "Application context should not be null");
	}
	
}






