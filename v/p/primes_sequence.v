module primes_sequence

// Generate zero-based prime terms using divisibility by all earlier primes.
@[export: 'primes_sequence']
pub fn primes_sequence(index i64) i64 {
	if index < 0 || index > 99 { return -1 }
	mut primes := [100]i64{}
	primes[0] = 2
	mut count := i64(1)
	mut candidate := i64(3)
	for count <= index {
		mut is_prime := true
		for i := i64(0); i < count; i++ {
			if candidate % primes[int(i)] == 0 {
				is_prime = false
				break
			}
		}
		if is_prime {
			primes[int(count)] = candidate
			count++
		}
		candidate += 2
	}
	return primes[int(index)]
}
