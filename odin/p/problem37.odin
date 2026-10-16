package problem37

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value == 2 || value == 3 do return true
	if value % 2 == 0 || value % 3 == 0 do return false
	for divisor := i64(5); divisor <= value / divisor; divisor += 6 {
		if value % divisor == 0 || value % (divisor + 2) == 0 do return false
	}
	return true
}

is_truncatable_prime :: proc "contextless" (value: i64) -> bool {
	if !is_prime(value) do return false
	for power := i64(10); power < value; power *= 10 {
		if !is_prime(value / power) || !is_prime(value % power) do return false
	}
	return true
}

@(export)
problem37 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 do return -1
	found := 0
	sum := i64(0)
	for candidate := i64(13); candidate <= 1_000_000 && found < 11; candidate += 2 {
		if is_truncatable_prime(candidate) {
			sum += candidate
			found += 1
		}
	}
	if found == 11 do return sum
	return -1
}
