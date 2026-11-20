package batch_gcd_small_range_precomputed

import "core:c"

MAX_VALUE :: 64
MAX_QUERIES :: 64
MAX_INPUT_LENGTH :: 2 + 2 * MAX_QUERIES
MAX_SMALL :: 8

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
batch_gcd_small_range_precomputed :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH + 1 do return -1
	limit_value := input[0]
	query_value := input[1]
	if limit_value < 1 || limit_value > i64(MAX_VALUE) || query_value < 0 ||
		query_value > i64(MAX_QUERIES) do return -1
	limit := int(limit_value)
	queries := int(query_value)
	if length != c.size_t(2 + 2 * queries) do return -1
	for query := 0; query < queries; query += 1 {
		left := input[2 + 2 * query]
		right := input[3 + 2 * query]
		if left < 0 || left > limit_value || right < 0 || right > limit_value do return -1
	}
	required := 8 * queries
	if output == nil || capacity < c.size_t(required) do return -2

	least: [MAX_VALUE + 1]int = {}
	primes: [MAX_VALUE + 1]int = {}
	prime_count := 0
	for value := 2; value <= limit; value += 1 {
		if least[value] == 0 {
			least[value] = value
			primes[prime_count] = value
			prime_count += 1
		}
		for index := 0; index < prime_count; index += 1 {
			prime := primes[index]
			composite := value * prime
			if composite > limit || prime > least[value] do break
			least[composite] = prime
		}
	}

	factors: [MAX_VALUE + 1][3]int = {}
	factors[1][0] = 1
	factors[1][1] = 1
	factors[1][2] = 1
	for value := 2; value <= limit; value += 1 {
		prime := least[value]
		quotient := value / prime
		a := factors[quotient][0] * prime
		b := factors[quotient][1]
		c_value := factors[quotient][2]
		if a > b { a, b = b, a }
		if b > c_value { b, c_value = c_value, b }
		if a > b { a, b = b, a }
		factors[value][0] = a
		factors[value][1] = b
		factors[value][2] = c_value
	}

	small_limit := 1
	for (small_limit + 1) * (small_limit + 1) <= limit { small_limit += 1 }
	gcd_table: [MAX_SMALL + 1][MAX_SMALL + 1]int = {}
	for left := 1; left <= small_limit; left += 1 {
		gcd_table[left][0] = left
		for right := 1; right < left; right += 1 {
			gcd_table[left][right] = gcd_table[right][left % right]
		}
	}

	for query := 0; query < queries; query += 1 {
		left := int(input[2 + 2 * query])
		remaining := int(input[3 + 2 * query])
		result := 0
		if left == 0 {
			result = remaining
		} else {
			result = 1
			for part := 0; part < 3; part += 1 {
				factor := factors[left][part]
				common := 1
				if factor <= small_limit {
					common = gcd_table[factor][remaining % factor]
				} else if remaining % factor == 0 {
					common = factor
				}
				remaining /= common
				result *= common
			}
		}
		store_i64_le(output, 8 * query, i64(result))
	}
	return i64(required)
}
