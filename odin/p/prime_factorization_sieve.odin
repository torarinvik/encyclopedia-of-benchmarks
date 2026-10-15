package prime_factorization_sieve

import "core:c"

write_u32le :: proc "contextless" (value: u32, output: [^]u8, position: c.size_t) {
	for byte := c.size_t(0); byte < 4; byte += 1 {
		output[position + byte] = u8((value >> (8 * byte)) & 255)
	}
}

// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
@(export)
prime_factorization_sieve :: proc "c" (value: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if value < 1 || value > 1_000_005 do return -1
	if value == 1 do return 0
	limit := int(value)
	is_prime := make([]bool, limit + 1)
	defer delete(is_prime)
	for index := 2; index <= limit; index += 1 { is_prime[index] = true }
	for prime := 2; prime <= limit / prime; prime += 1 {
		if !is_prime[prime] do continue
		for multiple := prime * prime; multiple <= limit; multiple += prime {
			is_prime[multiple] = false
		}
	}

	primes: [10]u32
	exponents: [10]u32
	count := 0
	remaining := value
	for prime := 2; prime <= limit && remaining > 1; prime += 1 {
		if !is_prime[prime] do continue
		exponent := u32(0)
		for remaining % i64(prime) == 0 {
			remaining /= i64(prime)
			exponent += 1
		}
		if exponent != 0 {
			primes[count] = u32(prime)
			exponents[count] = exponent
			count += 1
		}
	}
	required := c.size_t(count * 8)
	if output == nil || output_capacity < required do return -2
	for index := 0; index < count; index += 1 {
		write_u32le(primes[index], output, c.size_t(8 * index))
		write_u32le(exponents[index], output, c.size_t(8 * index + 4))
	}
	return i64(required)
}
