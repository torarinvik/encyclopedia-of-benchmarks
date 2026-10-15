package find_all_duplicates_hash_order

import "core:c"

MAX_INPUT_LENGTH :: 1024
TABLE_SIZE :: 2048

@(export)
find_all_duplicates_hash_order :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_INPUT_LENGTH) || (length != 0 && input == nil) do return -1

	keys: [TABLE_SIZE]i64
	counts: [TABLE_SIZE]int
	used: [TABLE_SIZE]bool
	insertion_order: [MAX_INPUT_LENGTH]int
	unique_count := 0

	for index := 0; index < int(length); index += 1 {
		remainder := input[index] % i64(TABLE_SIZE)
		if remainder < 0 do remainder += i64(TABLE_SIZE)
		slot := int(remainder)
		for used[slot] && keys[slot] != input[index] {
			slot = (slot + 1) % TABLE_SIZE
		}
		if !used[slot] {
			used[slot] = true
			keys[slot] = input[index]
			counts[slot] = 1
			insertion_order[unique_count] = slot
			unique_count += 1
		} else {
			counts[slot] += 1
		}
	}

	duplicate_count := 0
	for index := 0; index < unique_count; index += 1 {
		if counts[insertion_order[index]] > 1 do duplicate_count += 1
	}
	required := c.size_t(duplicate_count * 8)
	if output_capacity < required || (required != 0 && output == nil) do return -2

	written := c.size_t(0)
	for index := 0; index < unique_count; index += 1 {
		slot := insertion_order[index]
		if counts[slot] > 1 {
			bits := u64(keys[slot])
			for byte := 0; byte < 8; byte += 1 {
				output[written] = u8((bits >> u64(byte*8)) & 255)
				written += 1
			}
		}
	}
	return i64(duplicate_count)
}
