package double_factorial

// Iterative double factorial for the signed 64-bit benchmark contract.
@(export)
double_factorial :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 33 do return -1
	product := i64(1)
	for factor := n; factor > 1; factor -= 2 {
		product *= factor
	}
	return product
}
