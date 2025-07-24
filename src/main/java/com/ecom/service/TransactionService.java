package com.ecom.service;

import com.ecom.entity.Transaction;
import com.ecom.repository.TransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Scanner;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;

    @Autowired
    public TransactionService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    public List<Transaction> searchTransactionsByDate() {
        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter transaction date (YYYY-MM-DD): ");
        String dateString = scanner.nextLine();
        LocalDate localDate;
        try {
            localDate = LocalDate.parse(dateString, DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
            System.out.println("Invalid date format. Please use YYYY-MM-DD.");
            return List.of();
        }
        List<Transaction> transactions = transactionRepository.findByTranDate(localDate);
        if (!transactions.isEmpty()) {
            System.out.println("Transactions for date: " + localDate);
            displayTransactions(transactions);
        } else {
            System.out.println("No transactions found for the specified date.");
        }
        return transactions;
    }

    public List<Transaction> getAllTransactions() {
        return transactionRepository.findAll();
    }

    public Transaction createTransaction(Transaction transaction) {
        if (transaction == null || transaction.getRequiredField() == null) {
            throw new IllegalArgumentException("Transaction or required fields cannot be null");
        }
        return transactionRepository.save(transaction);
    }

    private void displayTransactions(List<Transaction> transactions) {
        for (Transaction transaction : transactions) {
            System.out.println(transaction);
        }
    }
}