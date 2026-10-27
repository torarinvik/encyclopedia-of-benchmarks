package point_pattern_translation_voting

import "core:c"

MAX_PATTERN :: 6
MAX_TARGET :: 8
MAX_COORD :: 16
MAX_PAIRS :: 48

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
point_pattern_translation_voting :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 31 do return -1
	pattern_raw, target_raw := input[0], input[1]
	if pattern_raw < 1 || pattern_raw > MAX_PATTERN || target_raw < 1 || target_raw > MAX_TARGET do return -1
	pattern_count, target_count := int(pattern_raw), int(target_raw)
	if length != c.size_t(2+2*(pattern_count+target_count)) do return -1
	px, py: [MAX_PATTERN]i64 = {}, {}
	tx, ty: [MAX_TARGET]i64 = {}, {}
	cursor := 2
	for i := 0; i < pattern_count; i += 1 {
		px[i], py[i] = input[cursor], input[cursor+1]; cursor += 2
		if px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD do return -1
		for j := 0; j < i; j += 1 { if px[i] == px[j] && py[i] == py[j] do return -1 }
	}
	for i := 0; i < target_count; i += 1 {
		tx[i], ty[i] = input[cursor], input[cursor+1]; cursor += 2
		if tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD do return -1
		for j := 0; j < i; j += 1 { if tx[i] == tx[j] && ty[i] == ty[j] do return -1 }
	}
	if output == nil do return -2
	dx, dy: [MAX_PAIRS]i64 = {}, {}
	pair_count := 0
	for p := 0; p < pattern_count; p += 1 { for t := 0; t < target_count; t += 1 {
		dx[pair_count], dy[pair_count] = tx[t]-px[p], ty[t]-py[p]; pair_count += 1
	}}
	for i := 1; i < pair_count; i += 1 {
		key_x, key_y := dx[i], dy[i]
		j := i
		for j > 0 && (dx[j-1] > key_x || (dx[j-1] == key_x && dy[j-1] > key_y)) {
			dx[j], dy[j] = dx[j-1], dy[j-1]; j -= 1
		}
		dx[j], dy[j] = key_x, key_y
	}
	best_count := 0
	best_x, best_y := dx[0], dy[0]
	for i := 0; i < pair_count; {
		ending := i+1
		for ending < pair_count && dx[ending] == dx[i] && dy[ending] == dy[i] { ending += 1 }
		if ending-i > best_count { best_count, best_x, best_y = ending-i, dx[i], dy[i] }
		i = ending
	}
	if capacity < 24 do return -2
	staged: [24]u8 = {}
	store_i64_le(&staged[0], 0, i64(best_count))
	store_i64_le(&staged[0], 8, best_x)
	store_i64_le(&staged[0], 16, best_y)
	for byte := 0; byte < 24; byte += 1 { output[byte] = staged[byte] }
	return 24
}
