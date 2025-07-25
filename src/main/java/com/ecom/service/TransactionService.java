package com.ecom.service;

import com.ecom.repository.CategoryRepository;
import com.ecom.model.Transaction;
import com.ecom.exception.TransactionRetrievalException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

@Service
public class TransactionService {

    private final CategoryRepository categoryRepository;
    private static final Logger logger = LoggerFactory.getLogger(TransactionService.class);

    @Autowired
    public TransactionService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    public List<Transaction> getTransactionsByDate(LocalDate date) {
        try {
            List<Transaction> transactions = categoryRepository.findTransactionsByDate(date);
            return transactions != null ? transactions : Collections.emptyList();
        } catch (Exception e) {
            logger.error("Error retrieving transactions for date: {}", date, e);
            throw new TransactionRetrievalException("Failed to retrieve transactions", e);
        }
    }
}