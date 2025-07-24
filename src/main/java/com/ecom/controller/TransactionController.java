package com.ecom.controller;

import com.ecom.service.TransactionService;
import com.ecom.model.Transaction;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@RestController
@RequestMapping("/transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping("/search-transactions")
    public ResponseEntity<?> searchTransactionsByDate(@RequestParam(required = false) String date) {
        if (date == null || !isValidDate(date)) {
            return ResponseEntity.badRequest().body("Invalid date format");
        }
        List<Transaction> transactions = transactionService.searchTransactionsByDate(date);
        if (!transactions.isEmpty()) {
            return ResponseEntity.ok(transactions);
        } else {
            return ResponseEntity.status(404).body("No transactions found for the specified date.");
        }
    }

    @GetMapping
    public ResponseEntity<List<Transaction>> getTransactions() {
        List<Transaction> transactions = transactionService.getAllTransactions();
        return ResponseEntity.ok(transactions);
    }

    @PostMapping
    public ResponseEntity<Transaction> createTransaction(@RequestBody Transaction transaction) {
        if (transaction == null || !isValidTransaction(transaction)) {
            return ResponseEntity.badRequest().body(null);
        }
        Transaction createdTransaction = transactionService.createTransaction(transaction);
        return ResponseEntity.status(201).body(createdTransaction);
    }

    private boolean isValidDate(String date) {
        try {
            LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE);
            return true;
        } catch (DateTimeParseException e) {
            return false;
        }
    }

    private boolean isValidTransaction(Transaction transaction) {
        return transaction.getId() != null && transaction.getAmount() != null && transaction.getDate() != null;
    }
}