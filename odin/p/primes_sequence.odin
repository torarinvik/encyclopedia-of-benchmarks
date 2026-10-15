package primes_sequence

// Generate zero-based prime terms using divisibility by all earlier primes.
@(export)
primes_sequence :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 99 do return -1
	primes: [100]i64 = {}
	primes[0] = 2
	count := i64(1)
	candidate := i64(3)
	for count <= index {
		is_prime := true
		for i := i64(0); i < count; i += 1 {
			if candidate % primes[i] == 0 {
				is_prime = false
				break
			}
		}
		if is_prime {
			primes[count] = candidate
			count += 1
		}
		candidate += 2
	}
	return primes[index]
}
