module fibonacci_search

// Fibonacci search in an ascending sequence for the shared benchmark contract.
@[export: 'fibonacci_search']
pub fn fibonacci_search(values &i64, length usize, target i64) i64 {
	if length == 0 {
		return -1
	}
	mut fib_minus_two := usize(0)
	mut fib_minus_one := usize(1)
	mut fib := usize(1)
	for fib < length {
		fib_minus_two = fib_minus_one
		fib_minus_one = fib
		fib = fib_minus_two + fib_minus_one
	}
	mut offset_plus_one := usize(0)
	for fib > 1 {
		mut index := offset_plus_one + fib_minus_two - 1
		if index >= length {
			index = length - 1
		}
		value := unsafe { values[index] }
		if value == target {
			return i64(index)
		}
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
	if fib_minus_one != 0 && offset_plus_one < length && unsafe { values[offset_plus_one] } == target {
		return i64(offset_plus_one)
	}
	return -1
}
