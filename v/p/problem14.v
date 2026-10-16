module problem14

fn collatz_length(start u64) u64 {
	mut current := start
	mut length := u64(1)
	for current != 1 {
		if length >= 10_000 { return 0 }
		if current % 2 == 0 {
			current /= 2
		} else {
			if current > 6_148_914_691_236_517_204 { return 0 }
			current = 3 * current + 1
		}
		length++
	}
	return length
}

@[export: 'problem14']
pub fn problem14(limit i64) i64 {
	if limit < 1 || limit > 1_000_000 { return -1 }
	mut best_start := u64(1)
	mut best_length := u64(1)
	mut start := u64(2)
	for start <= u64(limit) {
		length := collatz_length(start)
		if length == 0 { return -1 }
		if length > best_length {
			best_start = start
			best_length = length
		}
		start++
	}
	return i64(best_start)
}
