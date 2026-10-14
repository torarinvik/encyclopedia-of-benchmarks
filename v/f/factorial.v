module factorial

// Iterative factorial for the shared signed 64-bit benchmark contract.
@[export: 'factorial']
pub fn factorial(n i64) i64 {
	if n < 0 || n > 20 {
		return -1
	}

	mut product := i64(1)
	mut factor := i64(2)
	for factor <= n {
		product *= factor
		factor++
	}
	return product
}
