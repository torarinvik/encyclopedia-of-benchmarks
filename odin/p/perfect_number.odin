package perfect_number

// Check whether n equals the sum of its positive proper divisors.
@(export)
perfect_number :: proc "c" (n: i64) -> i64 {
	if n <= 1 do return 0
	if n > 1_000_000_000_000 do return -1

	number := u64(n)
	stride := 1 + (number & 1)
	divisor_sum := u64(1)
	if stride == 1 && number >= 4 {
		half := number >> 1
		divisor_sum = 3 if half == 2 else 3 + half
	}
	for factor := u64(3); ; factor += stride {
		partner := number / factor
		if factor > partner do break
		if partner * factor == number {
			divisor_sum += factor
			if partner != factor do divisor_sum += partner
			if divisor_sum > number do return 0
		}
	}
	return 1 if divisor_sum == number else 0
}
