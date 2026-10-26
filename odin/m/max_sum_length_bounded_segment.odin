package max_sum_length_bounded_segment

import "core:c"

MAX_N :: 32
MAX_INPUT :: 35

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
max_sum_length_bounded_segment :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64, lower64, upper64 := input[0], input[1], input[2]
	if n64 < 1 || n64 > MAX_N || lower64 < 1 || upper64 < lower64 || upper64 > n64 ||
		length != c.size_t(3+n64) do return -1
	n, lower, upper := int(n64), int(lower64), int(upper64)
	prefix: [MAX_N+1]i64
	for i := 0; i < n; i += 1 {
		value := input[3+i]
		if value < -10000 || value > 10000 do return -1
		prefix[i+1] = prefix[i] + value
	}
	if output == nil || capacity < 24 do return -2
	deque: [MAX_N+1]int
	head, tail := 0, 0
	best_sum: i64 = 0
	best_start, best_end := 0, 0
	have_best := false
	for end := lower; end <= n; end += 1 {
		added := end-lower
		for tail > head && prefix[deque[tail-1]] > prefix[added] { tail -= 1 }
		deque[tail] = added
		tail += 1
		earliest := 0
		if end > upper { earliest = end-upper }
		for head < tail && deque[head] < earliest { head += 1 }
		start := deque[head]
		total := prefix[end]-prefix[start]
		if !have_best || total > best_sum || (total == best_sum &&
			(start < best_start || (start == best_start && end < best_end))) {
			best_sum, best_start, best_end, have_best = total, start, end, true
		}
	}
	store_i64_le(output, 0, best_sum)
	store_i64_le(output, 8, i64(best_start))
	store_i64_le(output, 16, i64(best_end))
	return 24
}
