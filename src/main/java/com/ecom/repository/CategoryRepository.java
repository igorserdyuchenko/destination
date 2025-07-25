package com.ecom.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface CategoryRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findTransactionsByDate(LocalDate date);
}