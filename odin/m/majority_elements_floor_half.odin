package majority_elements_floor_half

import "core:c"

MAX_INPUT_LENGTH :: 256
TABLE_SIZE :: 512

@(export)
majority_elements_floor_half :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_INPUT_LENGTH) || (length != 0 && input == nil) do return -1

	keys: [TABLE_SIZE]i32
	counts: [TABLE_SIZE]int
	used: [TABLE_SIZE]bool
	insertion_order: [MAX_INPUT_LENGTH]int
	unique_count := 0

	for index := 0; index < int(length); index += 1 {
		value := input[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		remainder := value % i64(TABLE_SIZE)
		if remainder < 0 do remainder += i64(TABLE_SIZE)
		slot := int(remainder)
		key := i32(value)
		for used[slot] && keys[slot] != key {
			slot = (slot + 1) % TABLE_SIZE
		}
		if !used[slot] {
			used[slot] = true
			keys[slot] = key
			counts[slot] = 1
			insertion_order[unique_count] = slot
			unique_count += 1
		} else {
			counts[slot] += 1
		}
	}

	results: [MAX_INPUT_LENGTH]i32
	result_count := 0
	threshold := int(length) / 2
	for index := 0; index < unique_count; index += 1 {
		slot := insertion_order[index]
		if counts[slot] >= threshold {
			results[result_count] = keys[slot]
			result_count += 1
		}
	}
	for index := 1; index < result_count; index += 1 {
		value := results[index]
		position := index
		for position > 0 && results[position-1] > value {
			results[position] = results[position-1]
			position -= 1
		}
		results[position] = value
	}

	required := c.size_t(result_count * 4)
	if capacity < required || (required != 0 && output == nil) do return -2
	written := c.size_t(0)
	for index := 0; index < result_count; index += 1 {
		bits := u32(results[index])
		for byte := 0; byte < 4; byte += 1 {
			output[written] = u8((bits >> u32(byte*8)) & 255)
			written += 1
		}
	}
	return i64(result_count)
}
