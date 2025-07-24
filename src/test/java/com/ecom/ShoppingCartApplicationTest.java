package com.ecom;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class ShoppingCartApplicationTest {

    private final ShoppingCartApplication shoppingCart = new ShoppingCartApplication();

    @Test
    public void testAddPositiveIntegers() {
        assertEquals(5, shoppingCart.add(2, 3));
        assertEquals(10, shoppingCart.add(7, 3));
    }

    @Test
    public void testAddNegativeIntegers() {
        assertEquals(-5, shoppingCart.add(-2, -3));
        assertEquals(1, shoppingCart.add(-2, 3));
        assertEquals(-2, shoppingCart.add(-2, 0));
    }

    @Test
    public void testAddZero() {
        assertEquals(3, shoppingCart.add(0, 3));
        assertEquals(0, shoppingCart.add(0, 0));
    }

    @Test
    public void testAddLargeIntegers() {
        assertEquals(2147483647, shoppingCart.add(1073741824, 1073741823));
        assertEquals(-1, shoppingCart.add(2147483647, 1));
        assertEquals(-2147483648, shoppingCart.add(-2147483647, -1));
    }
}