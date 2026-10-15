package nthprime

// Expanding sieve strategy from the pinned Rust nth-prime routine.
@(export)
nthprime :: proc "c" (nth: i64) -> i64 {
	if nth < 1 || nth > 100 do return -1
	primes: [1600]u64
	total_prime: u64 = 0
	size_factor: u64 = 2
	size: u64 = u64(nth) * size_factor
	for total_prime < u64(nth) {
		if size > 1600 do return -1
		for index := 0; index < int(size); index += 1 do primes[index] = 1
		for index := 2; index < int(size); index += 1 {
			if primes[index] == 1 {
				for multiple := index; multiple < int(size); multiple += 1 {
					product := index * multiple
					if product < int(size) do primes[product] = 0
					else break
				}
			}
		}
		total_prime = 0
		for index := 2; index < int(size); index += 1 do total_prime += primes[index]
		size_factor += 1
		size = u64(nth) * size_factor
	}
	used_size := int(size - u64(nth))
	count: u64 = 0
	for index := 2; index < used_size; index += 1 {
		count += primes[index]
		if count == u64(nth) do return i64(index)
	}
	return -1
}
