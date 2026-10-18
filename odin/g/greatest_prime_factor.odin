package greatest_prime_factor

is_prime_trial :: proc(value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

// Greatest prime factor over the bounded primelib input domain.
@(export)
greatest_prime_factor :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 1_000_000 do return -1
	if n < 2 do return n
	if is_prime_trial(n) do return n

	quotient := n
	largest := i64(0)
	factor := i64(2)
	for quotient != 1 {
		if is_prime_trial(factor) && quotient % factor == 0 {
			largest = factor
			quotient /= factor
		} else {
			factor += 1
		}
	}
	return largest
}
