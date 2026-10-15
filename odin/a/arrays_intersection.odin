package arrays_intersection

import "core:c"

ARRAY_COUNT :: 3
MAX_ARRAY_LENGTH :: 64
MAX_INPUT_LENGTH :: ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1)
MAX_OCCURRENCES :: ARRAY_COUNT * MAX_ARRAY_LENGTH
TABLE_SIZE :: 257

// Count occurrences across all three arrays and emit first-seen keys with count three.
@(export)
arrays_intersection :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < ARRAY_COUNT || length > MAX_INPUT_LENGTH do return -1
	starts: [ARRAY_COUNT]int = {}
	sizes: [ARRAY_COUNT]int = {}
	position := 0
	for array := 0; array < ARRAY_COUNT; array += 1 {
		if position >= int(length) || input[position] < 0 || input[position] > MAX_ARRAY_LENGTH do return -1
		size := int(input[position])
		position += 1
		if size > int(length) - position do return -1
		starts[array] = position
		sizes[array] = size
		for index := 0; index < size; index += 1 {
			if input[position + index] < -2147483648 || input[position + index] > 2147483647 do return -1
		}
		position += size
	}
	if position != int(length) do return -1

	keys: [TABLE_SIZE]i64 = {}
	counts: [TABLE_SIZE]int = {}
	occupied: [TABLE_SIZE]bool = {}
	order: [MAX_OCCURRENCES]int = {}
	order_length := 0
	for array := 0; array < ARRAY_COUNT; array += 1 {
		for index := 0; index < sizes[array]; index += 1 {
			value := input[starts[array] + index]
			remainder := value % TABLE_SIZE
			if remainder < 0 { remainder += TABLE_SIZE }
			slot := int(remainder)
			for occupied[slot] && keys[slot] != value { slot = (slot + 1) % TABLE_SIZE }
			if !occupied[slot] {
				occupied[slot] = true
				keys[slot] = value
				counts[slot] = 0
				order[order_length] = slot
				order_length += 1
			}
			counts[slot] += 1
		}
	}

	match_count := 0
	for index := 0; index < order_length; index += 1 {
		if counts[order[index]] == ARRAY_COUNT do match_count += 1
	}
	if output_capacity < c.size_t(match_count * 4) || (match_count > 0 && output == nil) do return -2
	written := 0
	for index := 0; index < order_length; index += 1 {
		slot := order[index]
		if counts[slot] == ARRAY_COUNT {
			bits := u32(i32(keys[slot]))
			for byte := 0; byte < 4; byte += 1 {
				output[written * 4 + byte] = u8(bits >> (byte * 8))
			}
			written += 1
		}
	}
	return i64(written)
}
