package prime_check

// Trial-division primality check over the shared bounded integer domain.
@(export)
prime_check :: proc "c" (n: i64) -> i64 {
	if n < 2 do return 0
	if n > 2147483647 do return -1
	if n % 2 == 0 do return i64(n == 2)
	for factor := i64(3); factor <= n / factor; factor += 2 {
		if n % factor == 0 do return 0
	}
	return 1
}
