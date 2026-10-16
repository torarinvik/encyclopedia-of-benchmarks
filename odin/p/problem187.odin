package problem187

is_composite :: proc(bits: []u64, value: i64) -> bool {
	return (bits[int(value / 64)] & (u64(1) << u64(value % 64))) != 0
}

mark_composite :: proc(bits: []u64, value: i64) {
	bits[int(value / 64)] |= u64(1) << u64(value % 64)
}

@(export)
problem187 :: proc "c" (max_number: i64) -> i64 {
	if max_number < 0 || max_number > 100_000_000 do return -1
	prime_limit := max_number / 2
	if prime_limit <= 2 do return 0
	words := int((prime_limit + 63) / 64)
	composite := make([]u64, words)
	defer delete(composite)
	mark_composite(composite, 0)
	mark_composite(composite, 1)
	for prime := i64(2); prime <= (prime_limit - 1) / prime; prime += 1 {
		if is_composite(composite, prime) do continue
		for multiple := prime * prime; multiple < prime_limit; multiple += prime {
			mark_composite(composite, multiple)
		}
	}

	right_value := prime_limit - 1
	for right_value >= 2 && is_composite(composite, right_value) { right_value -= 1 }
	if right_value < 2 do return 0
	prime_count := i64(0)
	for value := i64(2); value <= right_value; value += 1 {
		if !is_composite(composite, value) { prime_count += 1 }
	}

	right_rank := prime_count - 1
	left_rank := i64(0)
	count := i64(0)
	for left_value := i64(2); left_value <= right_value; left_value += 1 {
		if is_composite(composite, left_value) do continue
		for right_rank >= left_rank && left_value * right_value >= max_number {
			right_rank -= 1
			right_value -= 1
			for right_value >= 2 && is_composite(composite, right_value) { right_value -= 1 }
		}
		if right_rank < left_rank do break
		count += right_rank - left_rank + 1
		left_rank += 1
	}
	return count
}
