package armstrong_number

// Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
@(export)
armstrong_number :: proc "c" (n: i64) -> i64 {
	if n < 0 do return 0
	if n == 0 do return 1
	digits := i64(0)
	for remaining := n; remaining > 0; remaining /= 10 { digits += 1 }
	total := i64(0)
	for remaining := n; remaining > 0; remaining /= 10 {
		digit := remaining % 10
		power := i64(1)
		for exponent := i64(0); exponent < digits; exponent += 1 { power *= digit }
		if power > n - total do return 0
		total += power
	}
	if total == n do return 1
	return 0
}
