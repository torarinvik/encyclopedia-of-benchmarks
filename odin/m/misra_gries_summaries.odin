package misra_gries_summaries

import "core:c"

MAX_K :: 8
MAX_ITEMS :: 64
MAX_INPUT :: 66

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
misra_gries_summaries :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	k64, count64 := input[0], input[1]
	if k64 < 1 || k64 > MAX_K || count64 < 0 || count64 > MAX_ITEMS ||
		length != c.size_t(2+count64) do return -1
	k, count := int(k64), int(count64)
	items: [MAX_K]i64
	counts: [MAX_K]i64
	for slot := 0; slot < k; slot += 1 do items[slot] = -1
	for index := 0; index < count; index += 1 {
		item := input[index+2]
		if item < 0 || item > 15 do return -1
		slot := 0
		for slot < k && items[slot] != item do slot += 1
		if slot < k {
			counts[slot] += 1
		} else {
			slot = 0
			for slot < k && counts[slot] != 0 do slot += 1
			if slot < k {
				items[slot] = item
				counts[slot] = 1
			} else {
				for slot = 0; slot < k; slot += 1 {
					counts[slot] -= 1
					if counts[slot] == 0 do items[slot] = -1
				}
			}
		}
	}
	used := 0
	for slot := 0; slot < k; slot += 1 do if counts[slot] > 0 do used += 1
	output_bytes := 8*(1+2*used)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	ordered_items: [MAX_K]i64
	ordered_counts: [MAX_K]i64
	at := 0
	for slot := 0; slot < k; slot += 1 {
		if counts[slot] <= 0 do continue
		position := at
		for position > 0 && ordered_items[position-1] > items[slot] {
			ordered_items[position] = ordered_items[position-1]
			ordered_counts[position] = ordered_counts[position-1]
			position -= 1
		}
		ordered_items[position] = items[slot]
		ordered_counts[position] = counts[slot]
		at += 1
	}
	store_i64_le(output, 0, i64(used))
	for index := 0; index < used; index += 1 {
		store_i64_le(output, 8*(1+2*index), ordered_items[index])
		store_i64_le(output, 8*(2+2*index), ordered_counts[index])
	}
	return i64(output_bytes)
}
