package smallest_number_with_n_divisors

import "core:c"

MAX_INPUT :: 3
MAX_STACK :: 128
MAX_DIVISOR_COUNT :: 63
MAX_LIMIT :: 1_000_000
PRIMES :: [5]i64{2, 3, 5, 7, 11}

@(export)
smallest_number_with_n_divisors :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT) || length != 2 do return -1
	divisor_count, limit := input[0], input[1]
	if divisor_count < 1 || divisor_count > MAX_DIVISOR_COUNT || limit < 1 || limit > MAX_LIMIT do return -1

	var remaining_stack: [MAX_STACK]i64
	var max_factor_stack: [MAX_STACK]i64
	var prime_index_stack: [MAX_STACK]i64
	var product_stack: [MAX_STACK]i64
	top := 1
	remaining_stack[0] = divisor_count
	max_factor_stack[0] = divisor_count
	product_stack[0] = 1
	best := limit + 1

	for top > 0 {
		top -= 1
		remaining := remaining_stack[top]
		max_factor := max_factor_stack[top]
		prime_index := prime_index_stack[top]
		product := product_stack[top]
		if remaining == 1 {
			best = min(best, product)
			continue
		}
		if prime_index >= i64(len(PRIMES)) do continue
		prime := PRIMES[int(prime_index)]
		factor_limit := min(max_factor, remaining)
		for factor := i64(2); factor <= factor_limit; factor += 1 {
			if remaining % factor != 0 do continue
			candidate := product
			valid := true
			for step := i64(1); step < factor; step += 1 {
				if candidate > limit / prime { valid = false; break }
				candidate *= prime
			}
			if valid && candidate < best {
				if top >= MAX_STACK do return -1
				remaining_stack[top] = remaining / factor
				max_factor_stack[top] = factor
				prime_index_stack[top] = prime_index + 1
				product_stack[top] = candidate
				top += 1
			}
		}
	}
	if best <= limit do return best
	return 0
}
