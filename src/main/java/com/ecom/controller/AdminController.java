package com.ecom.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ecom.service.TransactionService;
import com.ecom.model.Transaction;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private TransactionService transactionService;

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

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/transactions/search")
    public ResponseEntity<List<Transaction>> searchTransactionsByDate(@RequestParam("date") LocalDate date) {
        if (date == null) {
            return ResponseEntity.badRequest().body("Invalid date provided");
        }

        List<Transaction> transactions = transactionService.getTransactionsByDate(date);

        if (transactions.isEmpty()) {
            return ResponseEntity.status(404).body("No transactions found for the specified date");
        }

        return ResponseEntity.ok(transactions);
    }
}