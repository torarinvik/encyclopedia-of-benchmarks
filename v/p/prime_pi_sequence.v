module prime_pi_sequence

const max_index = i64(999)

@[export: 'prime_pi_sequence']
pub fn prime_pi_sequence(index i64) i64 {
	if index < 0 || index > max_index { return -1 }
	target := index + 1
	mut primes := [168]i64{}
	mut prime_count := 0
	if target >= 2 {
		primes[prime_count] = 2
		prime_count++
	}
	mut candidate := i64(3)
	for candidate <= target {
		mut is_prime := true
		mut i := 0
		for i < prime_count && is_prime {
			if candidate % primes[i] == 0 { is_prime = false }
			i++
		}
		if is_prime {
			primes[prime_count] = candidate
			prime_count++
		}
		candidate += 2
	}
	return i64(prime_count)
}
