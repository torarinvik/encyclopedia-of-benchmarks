package benchmarkgame_puzzle

import "core:c"

MAX_ARRAY_SIZE :: 100_000
MAX_ROUNDS :: 8
MAX_SCANS_PER_ARRAY :: 64

puzzle_rand :: proc(state: ^u64) -> u32 {
	state^ = state^ * 1_103_515_245 + 12_345
	shifted := u32(state^ >> 16)
	return shifted % 32_767 + 1
}

puzzle_rand_int :: proc(minimum, maximum: int, state: ^u64) -> int {
	range := maximum - minimum + 1
	draw := puzzle_rand(state)
	offset := int(f64(range) * (f64(draw) / 32_768.0))
	if offset == range { return offset + minimum - 1 }
	return offset + minimum
}

puzzle_shuffle :: proc(items: []i32, state: ^u64) {
	for index := len(items) - 1; index > 0; index -= 1 {
		range := index + 1
		draw := puzzle_rand(state)
		k := int(f64(range) * (f64(draw) / 32_768.0))
		chosen := k
		if k == range { chosen = k - 1 }
		items[index], items[chosen] = items[chosen], items[index]
	}
}

puzzle_find_duplicate :: proc(data: []i32) -> i32 {
	result := u32(0)
	for index := 0; index < len(data); index += 1 { result ^= u32(index + 1) ^ u32(data[index]) }
	result ^= u32(len(data))
	return i32(result)
}

puzzle_store_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
}

@(export)
benchmarkgame_puzzle :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	raw_size, raw_rounds, raw_scans := input[0], input[1], input[2]
	if raw_size < 1 || raw_size > MAX_ARRAY_SIZE || raw_rounds < 1 || raw_rounds > MAX_ROUNDS ||
		raw_scans < 1 || raw_scans > MAX_SCANS_PER_ARRAY do return -1
	size, rounds, scans := int(raw_size), int(raw_rounds), int(raw_scans)
	output_bytes := rounds * 4
	if output_capacity < c.size_t(output_bytes) || output == nil do return -2

	random_state := u64(1)
	for round := 0; round < rounds; round += 1 {
		data := make([]i32, size + 1)
		for index := 0; index <= size; index += 1 { data[index] = i32(index) }
		data[0] = i32(puzzle_rand_int(1, size, &random_state))
		puzzle_shuffle(data, &random_state)
		duplicate := i32(0)
		for scan := 0; scan < scans; scan += 1 { duplicate = puzzle_find_duplicate(data) }
		puzzle_store_i32_le(output, round * 4, duplicate)
		delete(data)
	}
	return i64(output_bytes)
}
