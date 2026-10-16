package choiceset

import "core:c"

MAX_OPERATIONS :: 1024
MAX_ELEMENTS :: 256
HASH_CAPACITY :: 512
MAX_KEY :: i64(1_000_000_000)

hash_slot :: proc "contextless" (value: i32) -> int {
	bits := u32(value)
	mixed := u64(bits) * 2_654_435_761
	return int(u32(mixed) >> 23)
}

find_slot :: proc "contextless" (keys: [^]i32, states: [^]i32, value: i32) -> int {
	slot := hash_slot(value)
	deleted := HASH_CAPACITY
	for probes := 0; probes < HASH_CAPACITY; probes += 1 {
		if states[slot] == 0 {
			if deleted < HASH_CAPACITY do return deleted
			return slot
		}
		if states[slot] == 2 {
			if deleted == HASH_CAPACITY do deleted = slot
		} else if keys[slot] == value do return slot
		slot = (slot + 1) % HASH_CAPACITY
	}
	return deleted
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte: u64 = 0; byte < 8; byte += 1 { output[offset + int(byte)] = u8(bits >> (8 * byte)) }
}

@(export)
choiceset :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > MAX_OPERATIONS do return -1
	operation_count := int(values[0])
	if length != c.size_t(1 + 2 * operation_count) do return -1
	output_bytes := operation_count * 8

	elements: [MAX_ELEMENTS]i32
	map_keys: [HASH_CAPACITY]i32
	map_indices: [HASH_CAPACITY]int
	states: [HASH_CAPACITY]i32 = {}
	results: [MAX_OPERATIONS]i64
	element_count := 0
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		operation := values[1 + 2 * operation_index]
		argument := values[2 + 2 * operation_index]
		if operation >= 1 && operation <= 3 {
			if argument < -MAX_KEY || argument > MAX_KEY do return -1
			key := i32(argument)
			slot := find_slot(&map_keys[0], &states[0], key)
			found := states[slot] == 1 && map_keys[slot] == key
			if operation == 1 {
				if found {
					results[operation_index] = 0
				} else {
					if element_count == MAX_ELEMENTS || slot >= HASH_CAPACITY do return -1
					elements[element_count] = key
					map_keys[slot] = key
					map_indices[slot] = element_count
					states[slot] = 1
					element_count += 1
					results[operation_index] = 1
				}
			} else if operation == 2 {
				results[operation_index] = i64(found)
			} else if !found {
				results[operation_index] = 0
			} else {
				index := map_indices[slot]
				last := element_count - 1
				if index != last {
					moved := elements[last]
					moved_slot := find_slot(&map_keys[0], &states[0], moved)
					if states[moved_slot] != 1 || map_keys[moved_slot] != moved do return -1
					elements[index] = moved
					map_indices[moved_slot] = index
				}
				element_count -= 1
				states[slot] = 2
				results[operation_index] = 1
			}
		} else if operation == 4 {
			if argument < 1 || argument > i64(element_count) do return -1
			results[operation_index] = i64(elements[int(argument) - 1])
		} else do return -1
	}
	if capacity < c.size_t(output_bytes) || (output_bytes > 0 && output == nil) do return -2
	for index := 0; index < operation_count; index += 1 { put_i64_le(output, index * 8, results[index]) }
	return i64(output_bytes)
}
