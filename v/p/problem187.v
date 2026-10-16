module problem187

fn is_composite(bits []u64, value i64) bool {
	return (bits[int(value >> 6)] >> u64(value & 63)) & u64(1) != 0
}

fn mark_composite(mut bits []u64, value i64) {
	bits[int(value >> 6)] |= u64(1) << u64(value & 63)
}

@[export: 'problem187']
pub fn problem187(max_number i64) i64 {
	if max_number < 0 || max_number > 100_000_000 { return -1 }
	prime_limit := max_number / 2
	if prime_limit <= 2 { return 0 }
	mut composite := []u64{len: int((prime_limit + 63) / 64)}
	mark_composite(mut composite, 0)
	mark_composite(mut composite, 1)
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

	mut right_value := prime_limit - 1
	for right_value >= 2 && is_composite(composite, right_value) { right_value-- }
	if right_value < 2 { return 0 }
	mut prime_count := i64(0)
	for value := i64(2); value <= right_value; value++ {
		if !is_composite(composite, value) { prime_count++ }
	}

	mut right_rank := prime_count - 1
	mut left_rank := i64(0)
	mut count := i64(0)
	for left_value := i64(2); left_value <= right_value; left_value++ {
		if is_composite(composite, left_value) { continue }
		for right_rank >= left_rank && left_value * right_value >= max_number {
			right_rank--
			right_value--
			for right_value >= 2 && is_composite(composite, right_value) { right_value-- }
		}
		if right_rank < left_rank { break }
		count += right_rank - left_rank + 1
		left_rank++
	}
	return count
}
