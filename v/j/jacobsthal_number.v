module jacobsthal_number

// Return J(n) for the bounded signed-64-bit Jacobsthal index.
@[export: 'jacobsthal_number']
pub fn jacobsthal_number(n i64) i64 {
	if n < 0 || n > 64 { return -1 }
	if n == 0 { return 0 }
	mut previous := i64(0)
	mut current := i64(1)
	mut index := i64(2)
	for index <= n {
		next := current + 2 * previous
		previous = current
		current = next
		index++
	}
	return current
}
