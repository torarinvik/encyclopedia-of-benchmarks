module nthprime

// Expanding sieve strategy from the pinned Rust nth-prime routine.
@[export: 'nthprime']
pub fn nthprime(nth i64) i64 {
	if nth < 1 || nth > 100 {
		return -1
	}
	mut primes := [1600]u64{}
	mut total_prime := u64(0)
	mut size_factor := u64(2)
	mut size := u64(nth) * size_factor
	for total_prime < u64(nth) {
		if size > 1600 {
			return -1
		}
		for index in 0 .. int(size) {
			primes[index] = 1
		}
		for index in 2 .. int(size) {
			if primes[index] == 1 {
				for multiple := index; multiple < int(size); multiple++ {
					product := index * multiple
					if product < int(size) {
						primes[product] = 0
					} else {
						break
					}
				}
			}
		}
		total_prime = 0
		for index in 2 .. int(size) {
			total_prime += primes[index]
		}
		size_factor++
		size = u64(nth) * size_factor
	}
	used_size := int(size - u64(nth))
	mut count := u64(0)
	for index in 2 .. used_size {
		count += primes[index]
		if count == u64(nth) {
			return i64(index)
		}
	}
	return -1
}
