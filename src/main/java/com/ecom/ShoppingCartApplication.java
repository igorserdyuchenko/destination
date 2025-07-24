package com.ecom;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.lang.*;

@SpringBootApplication
public class ShoppingCartApplication {

	public static void main(String[] args) {
		SpringApplication.run(ShoppingCartApplication.class, args);
	}

	/**
	 * Adds two integers and returns the sum.
	 *
	 * @param a the first integer
	 * @param b the second integer
	 * @return the sum of a and b
	 */
	public static int add(int a, int b) {
		return a + b;
	}
}