package fast_factorial

MAX_N :: 20
MAX_BUCKETS :: 8

exponent_in_factorial :: proc "contextless" (prime, n: i64) -> i64 {
	exponent := i64(0)
	quotient := n / prime
	for quotient > 0 {
		exponent += quotient
		quotient /= prime
	}
	return exponent
}

power_by_squaring :: proc "contextless" (base: i64, exponent_value: u32) -> i64 {
	result := i64(1)
	factor := base
	remaining := exponent_value
	for remaining > 0 {
		if (remaining & 1) != 0 do result *= factor
		remaining >>= 1
		if remaining > 0 do factor *= factor
	}
	return result
}

@(export)
fast_factorial :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > i64(MAX_N) do return -1
	if n < 2 do return 1

	is_prime: [MAX_N + 1]bool
	for candidate := 2; candidate <= int(n); candidate += 1 do is_prime[candidate] = true
	for prime := 2; prime * prime <= int(n); prime += 1 {
		if !is_prime[prime] do continue
		for multiple := prime * prime; multiple <= int(n); multiple += prime {
			is_prime[multiple] = false
		}
	}

	exponent_of_two := exponent_in_factorial(2, n)
	next_power_of_two := i64(1)
	power_log2 := u32(0)
	for next_power_of_two < exponent_of_two {
		next_power_of_two *= 2
		power_log2 += 1
	}
	bucket_count := int(power_log2 + 1)
	buckets: [MAX_BUCKETS]i64
	for bit := 0; bit < MAX_BUCKETS; bit += 1 do buckets[bit] = 1

	for candidate := 2; candidate <= int(n); candidate += 1 {
		if !is_prime[candidate] do continue
		exponent_bits := u32(exponent_in_factorial(i64(candidate), n))
		mask := u32(1)
		for bit := 0; bit < bucket_count; bit += 1 {
			if (exponent_bits & mask) != 0 do buckets[bit] *= i64(candidate)
			mask <<= 1
		}
	}

	result := i64(1)
	power_exponent := u32(1)
	for bit := 0; bit < bucket_count; bit += 1 {
		result *= power_by_squaring(buckets[bit], power_exponent)
		power_exponent <<= 1
	}
	return result
}
