module problem800

import math

fn is_composite(bits []u64, value i64) bool {
	return (bits[int(value >> 6)] >> u64(value & 63)) & u64(1) != 0
}

fn mark_composite(mut bits []u64, value i64) {
	bits[int(value >> 6)] |= u64(1) << u64(value & 63)
}

@[export: 'problem800']
pub fn problem800(base i64, degree i64) i64 {
	if base < 2 || base > 1000000 || degree < 1 || degree > 1000000 { return -1 }
	upper_bound := f64(degree) * math.log2(f64(base))
	prime_limit := i64(upper_bound)
	if prime_limit <= 2 { return 0 }
	mut composite := []u64{len: int((prime_limit + 63) / 64)}
	mut prime := i64(2)
	for prime <= (prime_limit - 1) / prime {
		if !is_composite(composite, prime) {
			mut multiple := prime * prime
			for multiple < prime_limit {
				mark_composite(mut composite, multiple)
				multiple += prime
			}
		}
		prime++
	}

	mut right_value := i64(0)
	mut prime_count := i64(0)
	for value := i64(2); value < prime_limit; value++ {
		if !is_composite(composite, value) { right_value = value; prime_count++ }
	}
	if prime_count < 2 { return 0 }
	mut right_rank := prime_count - 1
	mut left_rank := i64(0)
	mut left_value := i64(2)
	mut count := i64(0)
	for left_rank < right_rank {
		for is_composite(composite, left_value) { left_value++ }
		left_log := math.log2(f64(left_value))
		for f64(right_value) * left_log + f64(left_value) * math.log2(f64(right_value)) > upper_bound {
			right_rank--
			right_value--
			for right_value >= 2 && is_composite(composite, right_value) { right_value-- }
		}
		count += right_rank - left_rank
		left_rank++
		left_value++
	}
	return count
}
