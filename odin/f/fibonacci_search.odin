package fibonacci_search

import "core:c"

// Fibonacci search in an ascending sequence for the shared benchmark contract.
@(export)
fibonacci_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length == 0 do return -1
	fib_minus_two := c.size_t(0)
	fib_minus_one := c.size_t(1)
	fib := c.size_t(1)
	for fib < length {
		fib_minus_two = fib_minus_one
		fib_minus_one = fib
		fib = fib_minus_two + fib_minus_one
	}
	offset_plus_one := c.size_t(0)
	for fib > 1 {
		index := offset_plus_one + fib_minus_two - 1
		if index >= length do index = length - 1
		value := values[index]
		if value == target do return i64(index)
		if value < target {
			fib = fib_minus_one
			fib_minus_one = fib_minus_two
			fib_minus_two = fib - fib_minus_one
			offset_plus_one = index + 1
		} else {
			fib = fib_minus_two
			fib_minus_one -= fib_minus_two
			fib_minus_two = fib - fib_minus_one
		}
	}
	if fib_minus_one != 0 && offset_plus_one < length && values[offset_plus_one] == target {
		return i64(offset_plus_one)
	}
	return -1
}
