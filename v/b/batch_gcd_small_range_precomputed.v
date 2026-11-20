module batch_gcd_small_range_precomputed

import "core:c"

const max_value = 64
const max_queries = 64
const max_input_length = 2 + 2 * max_queries
const max_small = 8

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'batch_gcd_small_range_precomputed']
pub fn batch_gcd_small_range_precomputed(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length + 1 { return -1 }
	limit_value := unsafe { input[0] }
	query_value := unsafe { input[1] }
	if limit_value < 1 || limit_value > max_value || query_value < 0 || query_value > max_queries { return -1 }
	limit := int(limit_value)
	queries := int(query_value)
	if length != usize(2 + 2 * queries) { return -1 }
	for query in 0 .. queries {
		left := unsafe { input[2 + 2 * query] }
		right := unsafe { input[3 + 2 * query] }
		if left < 0 || left > limit_value || right < 0 || right > limit_value { return -1 }
	}
	required := 8 * queries
	if unsafe { output == nil } || capacity < usize(required) { return -2 }

	mut least := []int{len: max_value + 1}
	mut primes := []int{len: max_value + 1}
	mut prime_count := 0
	for value in 2 .. (limit + 1) {
		if least[value] == 0 {
			least[value] = value
			primes[prime_count] = value
			prime_count++
		}
		for index in 0 .. prime_count {
			prime := primes[index]
			composite := value * prime
			if composite > limit || prime > least[value] { break }
			least[composite] = prime
		}
	}

	mut factors := []int{len: (max_value + 1) * 3}
	factors[3] = 1
	factors[4] = 1
	factors[5] = 1
	for value in 2 .. (limit + 1) {
		prime := least[value]
		quotient := value / prime
		mut a := factors[3 * quotient] * prime
		mut b := factors[3 * quotient + 1]
		mut c_value := factors[3 * quotient + 2]
		if a > b { a, b = b, a }
		if b > c_value { b, c_value = c_value, b }
		if a > b { a, b = b, a }
		factors[3 * value] = a
		factors[3 * value + 1] = b
		factors[3 * value + 2] = c_value
	}

	mut small_limit := 1
	for (small_limit + 1) * (small_limit + 1) <= limit { small_limit++ }
	mut gcd_table := []int{len: (max_small + 1) * (max_small + 1)}
	for left in 1 .. (small_limit + 1) {
		gcd_table[(max_small + 1) * left] = left
		for right in 1 .. left {
			gcd_table[(max_small + 1) * left + right] = gcd_table[(max_small + 1) * right + (left % right)]
		}
	}

	for query in 0 .. queries {
		left := int(unsafe { input[2 + 2 * query] })
		mut remaining := int(unsafe { input[3 + 2 * query] })
		mut result := 0
		if left == 0 {
			result = remaining
		} else {
			result = 1
			for part in 0 .. 3 {
				factor := factors[3 * left + part]
				mut common := 1
				if factor <= small_limit {
					common = gcd_table[(max_small + 1) * factor + (remaining % factor)]
				} else if remaining % factor == 0 {
					common = factor
				}
				remaining /= common
				result *= common
			}
		}
		store_i64_le(mut output, 8 * query, i64(result))
	}
	i64(required)
}
