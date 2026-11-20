package smarandache_wellin_prime_prefix_scan

import "core:c"

small_prime :: proc(value: u64) -> bool {
	if value < 2 do return false
	divisor: u64 = 2
	for divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

multiply_mod :: proc(left, right, modulus: u64) -> u64 {
	return (left * right) % modulus
}

power_mod :: proc(initial_base, initial_exponent, modulus: u64) -> u64 {
	base := initial_base % modulus
	exponent := initial_exponent
	result: u64 = 1
	for exponent != 0 {
		if (exponent & 1) != 0 do result = multiply_mod(result, base, modulus)
		exponent >>= 1
		if exponent != 0 do base = multiply_mod(base, base, modulus)
	}
	return result
}

prime_prefix :: proc(value: u64) -> bool {
	small_primes := [12]u64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}
	bases := [3]u64{2, 7, 61}
	if value < 2 do return false
	for prime in small_primes {
		if value == prime do return true
		if value % prime == 0 do return false
	}
	odd_part := value - 1
	twos: u32 = 0
	for (odd_part & 1) == 0 {
		odd_part >>= 1
		twos += 1
	}
	for base in bases {
		witness := power_mod(base, odd_part, value)
		if witness == 1 || witness == value - 1 do continue
		round: u32 = 1
		for round < twos && witness != value - 1 {
			witness = multiply_mod(witness, witness, value)
			round += 1
		}
		if witness != value - 1 do return false
	}
	return true
}

@(export)
smarandache_wellin_prime_prefix_scan :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 2 do return -1
	count := input[0]
	if count < 0 || count > 6 || length != 1 do return -1

	values: [3]u64
	result_count := 0
	prefix: u64 = 0
	candidate: u64 = 2
	for index: i64 = 0; index < count; index += 1 {
		for !small_prime(candidate) {
			if candidate == 2 do candidate += 1 else candidate += 2
		}
		scale: u64 = 10
		for scale <= candidate do scale *= 10
		prefix = prefix * scale + candidate
		if prime_prefix(prefix) {
			values[result_count] = prefix
			result_count += 1
		}
		if candidate == 2 do candidate += 1 else candidate += 2
	}

	byte_count := result_count * 8
	if output == nil || capacity < c.size_t(byte_count) do return -2
	staged: [24]u8
	for item := 0; item < result_count; item += 1 {
		for byte := 0; byte < 8; byte += 1 {
			staged[item * 8 + byte] = u8((values[item] >> u64(byte * 8)) & 255)
		}
	}
	for byte := 0; byte < byte_count; byte += 1 do output[byte] = staged[byte]
	return i64(byte_count)
}
