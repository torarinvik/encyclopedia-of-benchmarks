package point_pattern_translation_lex_scan

import "core:c"

MAX_PATTERN :: 6
MAX_TARGET :: 8
MAX_COORD :: 16

point_less :: proc(ax, ay, bx, by: i64) -> bool {
	return ax < bx || (ax == bx && ay < by)
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
point_pattern_translation_lex_scan :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 31 do return -1
	pattern_raw, target_raw := input[0], input[1]
	if pattern_raw < 1 || pattern_raw > MAX_PATTERN || target_raw < 1 || target_raw > MAX_TARGET || pattern_raw > target_raw do return -1
	pattern_count, target_count := int(pattern_raw), int(target_raw)
	if length != c.size_t(2+2*(pattern_count+target_count)) do return -1
	px, py: [MAX_PATTERN]i64 = {}, {}
	tx, ty: [MAX_TARGET]i64 = {}, {}
	cursor := 2
	for i := 0; i < pattern_count; i += 1 {
		px[i], py[i] = input[cursor], input[cursor+1]; cursor += 2
		if px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD do return -1
		if i > 0 && !point_less(px[i-1], py[i-1], px[i], py[i]) do return -1
	}
	for i := 0; i < target_count; i += 1 {
		tx[i], ty[i] = input[cursor], input[cursor+1]; cursor += 2
		if tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD do return -1
		if i > 0 && !point_less(tx[i-1], ty[i-1], tx[i], ty[i]) do return -1
	}
	if output == nil || capacity < 24 do return -2

	found, best_x, best_y: i64 = 0, 0, 0
	for anchor := 0; anchor < target_count; anchor += 1 {
		dx, dy := tx[anchor]-px[0], ty[anchor]-py[0]
		target_index := anchor + 1
		matches := true
		for pattern_index := 1; pattern_index < pattern_count; pattern_index += 1 {
			wanted_x, wanted_y := px[pattern_index]+dx, py[pattern_index]+dy
			for target_index < target_count && point_less(tx[target_index], ty[target_index], wanted_x, wanted_y) { target_index += 1 }
			if target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y { matches = false; break }
			target_index += 1
		}
		if matches { found, best_x, best_y = 1, dx, dy; break }
	}
	staged: [24]u8 = {}
	store_i64_le(&staged[0], 0, found); store_i64_le(&staged[0], 8, best_x); store_i64_le(&staged[0], 16, best_y)
	for byte := 0; byte < 24; byte += 1 { output[byte] = staged[byte] }
	return 24
}
