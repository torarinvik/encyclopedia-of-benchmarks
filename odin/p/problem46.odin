package problem46

const MAX_ODD_COMPOSITE :: 99_999

is_prime :: proc "contextless" (number: i64) -> bool {
	if number < 2 do return false
	if number < 4 do return true
	if number % 2 == 0 || number % 3 == 0 do return false
	for divisor := i64(5); divisor <= number / divisor; divisor += 6 {
		if number % divisor == 0 || number % (divisor + 2) == 0 do return false
	}
	return true
}

find_first_counterexample :: proc "contextless" () -> i64 {
	for candidate := i64(3); candidate <= MAX_ODD_COMPOSITE; candidate += 2 {
		if is_prime(candidate) do continue
		represented := false
		for square := i64(0); 2 * square * square <= candidate; square += 1 {
			if is_prime(candidate - 2 * square * square) {
				represented = true
				break
			}
		}
		if !represented do return candidate
	}
	return -1
}

@(export)
problem46 :: proc "c" (placeholder: i64) -> i64 {
	if placeholder != 0 do return -1
	return find_first_counterexample()
}
