package faster_perfect_numbers

import "core:c"

MAX_INPUT :: i64(2305843009213693951)

get_prime_limit :: proc "contextless" (value: i64) -> u64 {
	scaled := u64(value) * 8 + 1
	limit: u64 = 0
	for scaled >= 4 {
		scaled /= 4
		limit += 1
	}
	return limit
}

is_prime :: proc "contextless" (value: u64) -> bool {
	if value < 2 do return false
	for divisor: u64 = 2; divisor * divisor <= value; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

is_mersenne_prime :: proc "contextless" (exponent: u64) -> bool {
	if exponent == 2 do return true
	if exponent < 2 do return false
	modulus := (u64(1) << u32(exponent)) - 1
	residue: u64 = 4
	for iteration: u64 = 0; iteration < exponent - 2; iteration += 1 {
		residue = (residue * residue - 2) % modulus
	}
	return residue == 0
}

@(export)
faster_perfect_numbers :: proc "c" (value: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if value < 0 || value > MAX_INPUT do return -1
	perfects: [8]i64
	count: int = 0
	limit := get_prime_limit(value)
	for exponent: u64 = 2; exponent <= limit; exponent += 1 {
		if !is_prime(exponent) || !is_mersenne_prime(exponent) do continue
		mersenne := (u64(1) << u32(exponent)) - 1
		perfect := mersenne * (u64(1) << u32(exponent - 1))
		if perfect <= u64(value) {
			perfects[count] = i64(perfect)
			count += 1
		}
	}
	required := c.size_t(count * 8)
	if required > 0 && output == nil do return -2
	if output_capacity < required do return -2
	for index in 0 ..< count {
		bits := u64(perfects[index])
		for byte in 0 ..< 8 {
			output[index * 8 + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
	return i64(required)
}

main :: proc() {}
