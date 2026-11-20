package erdos_selfridge_prime_class

import "core:c"

MAX_PRIME :: i64(100_000)

es_is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	for divisor := i64(3); divisor <= value / divisor; divisor += 2 {
		if value % divisor == 0 do return false
	}
	return true
}

es_class_for_prime :: proc "contextless" (prime, direction: i64) -> i64 {
	remainder := prime + direction
	best := i64(1)
	for divisor := i64(2); divisor <= remainder / divisor; divisor += 1 {
		if remainder % divisor != 0 do continue
		if divisor > 3 {
			candidate := i64(1) + es_class_for_prime(divisor, direction)
			if candidate > best do best = candidate
		}
		for remainder % divisor == 0 {
			remainder /= divisor
		}
	}
	if remainder > 3 {
		candidate := i64(1) + es_class_for_prime(remainder, direction)
		if candidate > best do best = candidate
	}
	return best
}

@(export)
erdos_selfridge_prime_class :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 3 do return -1
	if length != 2 do return -1
	prime := values[0]
	direction := values[1]
	if prime < 2 || prime > MAX_PRIME || (direction != -1 && direction != 1) do return -1
	if !es_is_prime(prime) do return -1
	return es_class_for_prime(prime, direction)
}

