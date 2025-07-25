package com.ecom.service;

import com.ecom.repository.TransactionRepository;
import com.ecom.model.Transaction;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Scanner;

@Service
public class TransactionService {
    private final TransactionRepository transactionRepository;

    public TransactionService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    public void searchTransactionsByDate() {
        String date;
        System.out.print("Enter the transaction date (YYYY-MM-DD): ");
        try (Scanner scanner = new Scanner(System.in)) {
            date = scanner.nextLine().trim();
        }
        LocalDate transactionDate;
        try {
            transactionDate = LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            System.out.println("Invalid date format. Please use YYYY-MM-DD.");
            return;
        }
        List<Transaction> transactions = transactionRepository.findByTranDate(transactionDate);
        if (!transactions.isEmpty()) {
            System.out.println("Transactions for date: " + transactionDate);
            displayTransactions(transactions);
        } else {
            System.out.println("No transactions found for the specified date.");
        }
    }

    private void displayTransactions(List<Transaction> transactions) {
        for (Transaction transaction : transactions) {
            System.out.println(transaction);
        }
    }
}