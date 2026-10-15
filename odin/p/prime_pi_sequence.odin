package prime_pi_sequence

MAX_INDEX :: i64(999)

@(export, link_name="prime_pi_sequence")
prime_pi_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > MAX_INDEX do return -1
	target := index + 1
	primes: [168]i64
	prime_count: i64 = 0
	if target >= 2 {
		primes[prime_count] = 2
		prime_count += 1
	}
	for candidate: i64 = 3; candidate <= target; candidate += 2 {
		is_prime := true
		for i: i64 = 0; i < prime_count && is_prime; i += 1 {
			if candidate % primes[i] == 0 do is_prime = false
		}
		if is_prime {
			primes[prime_count] = candidate
			prime_count += 1
		}
	}
	return prime_count
}

main :: proc() {}
