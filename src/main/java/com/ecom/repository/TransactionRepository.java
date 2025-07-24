package com.ecom.repository;

import com.ecom.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByTranDate(LocalDate tranDate);
    List<Transaction> findByUserId(Long userId);
}