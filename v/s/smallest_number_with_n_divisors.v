module smallest_number_with_n_divisors

const max_input = 3
const max_stack = 128
const max_divisor_count = i64(63)
const max_limit = i64(1_000_000)
const primes = [5]i64{2, 3, 5, 7, 11}

@[export: 'smallest_number_with_n_divisors']
pub fn smallest_number_with_n_divisors(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input || length != 2 { return -1 }
		divisor_count, limit := input[0], input[1]
		if divisor_count < 1 || divisor_count > max_divisor_count || limit < 1 || limit > max_limit { return -1 }

		mut remaining_stack := [max_stack]i64{}
		mut max_factor_stack := [max_stack]i64{}
		mut prime_index_stack := [max_stack]i64{}
		mut product_stack := [max_stack]i64{}
		mut top := 1
		remaining_stack[0] = divisor_count
		max_factor_stack[0] = divisor_count
		product_stack[0] = 1
		mut best := limit + 1

		for top > 0 {
			top--
			remaining := remaining_stack[top]
			max_factor := max_factor_stack[top]
			prime_index := prime_index_stack[top]
			product := product_stack[top]
			if remaining == 1 {
				if product < best { best = product }
				continue
			}
			if prime_index >= i64(primes.len) { continue }
			prime := primes[int(prime_index)]
			factor_limit := if max_factor < remaining { max_factor } else { remaining }
			mut factor := i64(2)
			for factor <= factor_limit {
				if remaining % factor == 0 {
					mut candidate := product
					mut valid := true
					mut step := i64(1)
					for step < factor {
						if candidate > limit / prime { valid = false; break }
						candidate *= prime
						step++
					}
					if valid && candidate < best {
						if top >= max_stack { return -1 }
						remaining_stack[top] = remaining / factor
						max_factor_stack[top] = factor
						prime_index_stack[top] = prime_index + 1
						product_stack[top] = candidate
						top++
					}
				}
				factor++
			}
		}
		return if best <= limit { best } else { i64(0) }
	}
}
