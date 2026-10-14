module double_factorial

// Iterative double factorial for the signed 64-bit benchmark contract.
@[export: 'double_factorial']
pub fn double_factorial(n i64) i64 {
	if n < 0 || n > 33 { return -1 }
	mut product := i64(1)
	mut factor := n
	for factor > 1 {
		product *= factor
		factor -= 2
	}
	return product
}
