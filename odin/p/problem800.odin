package problem800

import "core:math"

is_composite :: proc(bits: []u64, value: i64) -> bool {
	return (bits[int(value / 64)] & (u64(1) << u64(value % 64))) != 0
}

mark_composite :: proc(bits: []u64, value: i64) {
	bits[int(value / 64)] |= u64(1) << u64(value % 64)
}

@(export)
problem800 :: proc "c" (base, degree: i64) -> i64 {
	if base < 2 || base > 1_000_000 || degree < 1 || degree > 1_000_000 do return -1
	upper_bound := f64(degree) * math.log2_f64(f64(base))
	prime_limit := i64(upper_bound)
	if prime_limit <= 2 do return 0
	composite := make([]u64, int((prime_limit + 63) / 64))
	defer delete(composite)
	for prime := i64(2); prime <= (prime_limit - 1) / prime; prime += 1 {
		if is_composite(composite, prime) do continue
		for multiple := prime * prime; multiple < prime_limit; multiple += prime {
			mark_composite(composite, multiple)
		}
	}

	right_value := i64(0)
	prime_count := i64(0)
	for value := i64(2); value < prime_limit; value += 1 {
		if !is_composite(composite, value) { right_value = value; prime_count += 1 }
	}
	if prime_count < 2 do return 0
	right_rank := prime_count - 1
	left_rank := i64(0)
	left_value := i64(2)
	count := i64(0)
	for left_rank < right_rank {
		for is_composite(composite, left_value) { left_value += 1 }
		left_log := math.log2_f64(f64(left_value))
		for f64(right_value) * left_log + f64(left_value) * math.log2_f64(f64(right_value)) > upper_bound {
			right_rank -= 1
			right_value -= 1
			for right_value >= 2 && is_composite(composite, right_value) { right_value -= 1 }
		}
		count += right_rank - left_rank
		left_rank += 1
		left_value += 1
	}
	return count
}
