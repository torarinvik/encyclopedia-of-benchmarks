package stream_sieve

import "core:c"

MAX_PRIMES :: 100

prime_cache: [MAX_PRIMES]i32
prime_count: int
next_candidate: i32 = 3

is_prime_candidate :: proc(candidate: i32) -> bool {
	for index := 0; index < prime_count; index += 1 {
		divisor := prime_cache[index]
		if divisor > candidate / divisor do break
		if candidate % divisor == 0 do return false
	}
	return true
}

extend_prime_cache :: proc(requested_count: int) {
	if prime_count == 0 {
		prime_cache[0] = 2
		prime_count = 1
	}
	for prime_count < requested_count {
		candidate := next_candidate
		next_candidate += 1
		if is_prime_candidate(candidate) {
			prime_cache[prime_count] = candidate
			prime_count += 1
		}
	}
}

@(export, link_name="stream_sieve")
stream_sieve :: proc "c" (number_of_primes: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if number_of_primes < i64(-2147483648) || number_of_primes > i64(MAX_PRIMES) do return -1
	if number_of_primes <= 0 do return 0
	count := int(number_of_primes)
	required := c.size_t(count * 4)
	if output == nil || output_capacity < required do return -2

	extend_prime_cache(count)
	for index := 0; index < count; index += 1 {
		bits := u32(prime_cache[index])
		for byte := 0; byte < 4; byte += 1 {
			output[index * 4 + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
	return i64(required)
}
