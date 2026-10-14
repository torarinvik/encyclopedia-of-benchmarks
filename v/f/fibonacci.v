module fibonacci

// Iterative Fibonacci for the shared signed 64-bit benchmark contract.
@[export: 'fibonacci']
pub fn fibonacci(n i64) i64 {
	if n < 0 || n > 92 {
		return -1
	}
	if n == 0 {
		return 0
	}

	mut previous := i64(0)
	mut current := i64(1)
	mut index := i64(1)
	for index < n {
		next := previous + current
		previous = current
		current = next
		index++
	}
	return current
}
