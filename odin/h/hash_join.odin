package hash_join

import "core:c"

MAX_ROWS :: 8
HASH_CAPACITY :: 17
MAX_INPUT :: 19
MAX_OUTPUT :: 64

bucket_for :: proc(key: i64) -> int {
	remainder := key % i64(HASH_CAPACITY)
	if remainder < 0 do remainder += i64(HASH_CAPACITY)
	return int(remainder)
}

@(export)
hash_join :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	left_value, right_value := input[0], input[1]
	if left_value < 0 || left_value > MAX_ROWS || right_value < 0 || right_value > MAX_ROWS do return -1
	left_count, right_count := int(left_value), int(right_value)
	if int(length) != 2 + left_count + right_count do return -1

	build_left := left_count < right_count
	build_count := if build_left do left_count else right_count
	probe_count := if build_left do right_count else left_count
	build_offset := if build_left do 2 else 2 + left_count
	probe_offset := if build_left do 2 + left_count else 2
	keys: [HASH_CAPACITY]i64 = 0
	occupied: [HASH_CAPACITY]bool = false
	heads: [HASH_CAPACITY]int = -1
	tails: [HASH_CAPACITY]int = -1
	next_row: [MAX_ROWS]int = -1
	staged: [MAX_OUTPUT]u8 = 0

	for row := 0; row < build_count; row += 1 {
		key := input[build_offset + row]
		slot := bucket_for(key)
		for occupied[slot] && keys[slot] != key { slot = (slot + 1) % HASH_CAPACITY }
		if !occupied[slot] { occupied[slot] = true; keys[slot] = key }
		if tails[slot] < 0 { heads[slot] = row }
		else { next_row[tails[slot]] = row }
		tails[slot] = row
	}

	match_count := 0
	for probe_row := 0; probe_row < probe_count; probe_row += 1 {
		key := input[probe_offset + probe_row]
		slot := bucket_for(key)
		for occupied[slot] && keys[slot] != key { slot = (slot + 1) % HASH_CAPACITY }
		if !occupied[slot] do continue
		for build_row := heads[slot]; build_row >= 0; build_row = next_row[build_row] {
			left_id := if build_left do build_row else probe_row
			right_id := if build_left do probe_row else build_row
			staged[match_count] = u8((left_id << 4) | right_id)
			match_count += 1
		}
	}
	if output == nil || output_capacity < c.size_t(match_count) do return -2
	for index := 0; index < match_count; index += 1 { output[index] = staged[index] }
	return i64(match_count)
}
