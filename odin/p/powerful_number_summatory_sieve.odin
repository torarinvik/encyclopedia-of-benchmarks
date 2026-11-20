package powerful_number_summatory_sieve

import "core:c"

MAX_INPUT_LENGTH :: c.size_t(2)
MAX_SIEVE_LIMIT :: 1_000

accumulate_powerful :: proc "contextless" (n: i64, primes: [^]i64, prime_count, start_index: int,
		product, h_product: i64, total: ^i64) {
	remaining := n / product
	for prime_index := start_index; prime_index < prime_count; prime_index += 1 {
		prime := primes[prime_index]
		if prime > remaining / prime do break
		prime_power := prime * prime
		h_power := prime - 1
		for prime_power <= remaining {
			next_product := product * prime_power
			next_h_product := h_product * h_power
			total^ += next_h_product * (n / next_product)
			accumulate_powerful(n, primes, prime_count, prime_index+1,
				next_product, next_h_product, total)
			if prime_power > remaining / prime do break
			prime_power *= prime
			h_power *= prime
		}
	}
}

@(export)
powerful_number_summatory_sieve :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if length != 1 do return -1
	n := input[0]
	if n < 1 || n > 1_000_000 do return -1

	limit := 1
	for limit+1 <= int(n)/(limit+1) { limit += 1 }
	composite: [MAX_SIEVE_LIMIT+1]bool
	primes: [MAX_SIEVE_LIMIT+1]i64
	prime_count := 0
	for candidate := 2; candidate <= limit; candidate += 1 {
		if !composite[candidate] {
			primes[prime_count] = i64(candidate)
			prime_count += 1
			if candidate <= limit/candidate {
				for multiple := candidate*candidate; multiple <= limit; multiple += candidate {
					composite[multiple] = true
				}
			}
		}
	}
	total := n // The d=1 term contributes h(1)*N = N.
	accumulate_powerful(n, &primes[0], prime_count, 0, 1, 1, &total)
	return total
}
