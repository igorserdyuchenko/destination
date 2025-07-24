package com.ecom.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;

@Controller
@RequestMapping("/admin")
public class AdminController {
	
	@GetMapping("/")
	public String index() {
		return "admin/index";
	}
	
	@GetMapping("/loadAddProduct")
	public String loadAddProduct() {
		return "admin/add_product";
	}
	
	@GetMapping("/category")
	public String category() {
		return "admin/category";
	}

	@PostMapping("/agents/add")
	public ResponseEntity<?> add(@RequestBody Agent agent) {
		if (!isUnique(agent.getAgentId(), agent.getEnvironment())) {
			throw new IllegalArgumentException("Agent ID must be unique");
		}
		if (!isValidAgentType(agent.getAgentType())) {
			throw new IllegalArgumentException("Invalid agent type");
		}
		if (!isWithinBounds(agent.getInitialPosition(), agent.getEnvironment())) {
			throw new IllegalArgumentException("Initial position is out of bounds");
		}
		if (!isValidState(agent.getAgentType(), agent.getInitialState())) {
			throw new IllegalArgumentException("Invalid initial state for the agent type");
		}
		// Assume centralRegistry.add(agent) is called here
		return ResponseEntity.ok(agent);
	}

	@PostMapping("/admin/divide")
	public ResponseEntity<Double> divide(@RequestParam double numerator, @RequestParam double denominator) {
		if (denominator == 0) {
			return ResponseEntity.badRequest().body("Error: Division by zero is not allowed.");
		}
		double result = numerator / denominator;
		return ResponseEntity.ok(result);
	}

	@PostMapping("/api/admin/subtract")
	public ResponseEntity<Double> subtract(@RequestBody double... values) {
		if (values.length < 2) {
			return ResponseEntity.badRequest().body("At least two values are required for subtraction.");
		}
		double result = values[0];
		for (int i = 1; i < values.length; i++) {
			result -= values[i];
		}
		return ResponseEntity.ok(result);
	}

	@PostMapping("/admin/multiply")
	public ResponseEntity<Double> multiply(@RequestBody double... values) {
		if (values.length < 2) {
			return ResponseEntity.badRequest().body("At least two values are required for multiplication.");
		}
		double result = 1;
		for (double value : values) {
			result *= value;
		}
		return ResponseEntity.ok(result);
	}

	public static void main(String[] args) {
		int x = 10;
		int y = 5;
		System.out.printf("Addition: %d + %d = %d%n", x, y, add(x, y));
		System.out.printf("Subtraction: %d - %d = %d%n", x, y, subtract(x, y));
		System.out.printf("Multiplication: %d * %d = %d%n", x, y, multiply(x, y));
		System.out.printf("Division: %d / %d = %f%n", x, y, divide(x, y));
	}

	private static int add(int a, int b) {
		return a + b;
	}

	private static int subtract(int a, int b) {
		return a - b;
	}

	private static int multiply(int a, int b) {
		return a * b;
	}

	private static double divide(int a, int b) {
		return (double) a / b;
	}

	private boolean isUnique(String agentId, String environment) {
		return true;
	}

	private boolean isValidAgentType(String agentType) {
		return true;
	}

	private boolean isWithinBounds(double[] initialPosition, String environment) {
		return true;
	}

	private boolean isValidState(String agentType, String initialState) {
		return true;
	}
}