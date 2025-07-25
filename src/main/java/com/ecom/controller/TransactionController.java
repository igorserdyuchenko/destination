package com.ecom.controller;

import com.ecom.service.TransactionService;
import com.ecom.entity.Transaction;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.access.prepost.PreAuthorize;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

@RestController
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping("/search-transactions-by-date")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Transaction>> searchTransactionsByDate(@RequestParam String date) {
        if (date == null || !date.matches("\\d{4}-\\d{2}-\\d{2}")) {
            return ResponseEntity.badRequest().body(List.of("Invalid date format"));
        }
        LocalDate localDate;
        try {
            localDate = LocalDate.parse(date);
        } catch (DateTimeParseException e) {
            return ResponseEntity.badRequest().body(List.of("Invalid date format"));
        }
        List<Transaction> transactions = transactionService.searchTransactionsByDate(localDate);
        if (!transactions.isEmpty()) {
            return ResponseEntity.ok(transactions);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(List.of("No transactions found"));
        }
    }
}