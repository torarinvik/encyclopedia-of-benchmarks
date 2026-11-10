module perfect_number

// Check whether n equals the sum of its positive proper divisors.
@[export: 'perfect_number']
pub fn perfect_number(n i64) i64 {
	if n <= 1 { return 0 }
	if n > 1_000_000_000_000 { return -1 }

	number := u64(n)
	stride := u64(1) + (number & 1)
	mut divisor_sum := u64(1)
	if stride == 1 && number >= 4 {
		half := number >> 1
		divisor_sum = if half == 2 { u64(3) } else { 3 + half }
	}
	mut factor := u64(3)
	for {
		partner := number / factor
		if factor > partner { break }
		if partner * factor == number {
			divisor_sum += factor
			if partner != factor { divisor_sum += partner }
			if divisor_sum > number { return 0 }
		}
		factor += stride
	}
	return if divisor_sum == number { i64(1) } else { i64(0) }
}
