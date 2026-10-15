package germain_prime_and_safe_prime

import "core:c"

MAX_NUMBER :: i64(1_000_000)

is_prime :: proc "contextless" (value: i64) -> bool {
	if value == 2 do return true
	if value < 2 || value % 2 == 0 do return false
	for divisor := i64(3); divisor <= value / divisor; divisor += 2 {
		if value % divisor == 0 do return false
	}
	return true
}

@(export)
germain_prime_and_safe_prime :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	number := values[0]
	selector := values[1]
	if number < 1 || number > MAX_NUMBER || selector < 0 || selector > 1 do return -1
	if selector == 0 {
		if is_prime(number) && is_prime(2 * number + 1) do return 1
		return 0
	}
	if (number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2) do return 1
	return 0
}
