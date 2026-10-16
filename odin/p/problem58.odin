package problem58

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value < 4 do return true
	if value % 2 == 0 || value % 3 == 0 do return false
	for divisor := i64(5); divisor <= value / divisor; divisor += 6 {
		if value % divisor == 0 || value % (divisor + 2) == 0 do return false
	}
	return true
}

@(export)
problem58 :: proc "c" (ratio: f64) -> f64 {
	if !(ratio >= 0.1 && ratio <= 0.6) do return -1.0
	side := i64(3)
	prime_count := i64(3)
	for f64(prime_count) / f64(2 * side - 1) >= ratio {
		square := side * side
		step := side + 1
		if is_prime(square + step) do prime_count += 1
		if is_prime(square + 2 * step) do prime_count += 1
		if is_prime(square + 3 * step) do prime_count += 1
		side += 2
	}
	return f64(side)
}
