package lru

import "core:c"

MAX_INPUT_LENGTH :: 99
MAX_OPERATIONS :: 32
MAX_CAPACITY :: 16
MAX_OUTPUT_FIELDS :: 114

append :: proc(records: [^]i64, count: ^int, value: i64) {
	records[count^] = value
	count^ += 1
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
lru :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	capacity_value := input[0]
	operation_count := input[1]
	if capacity_value < 2 || capacity_value > i64(MAX_CAPACITY) || operation_count < 0 || operation_count > i64(MAX_OPERATIONS) || int(length) != 2+3*int(operation_count) do return -1
	capacity := int(capacity_value)
	keys: [MAX_CAPACITY]i64
	values: [MAX_CAPACITY]i64
	seen: [MAX_OPERATIONS]i64
	order: [MAX_CAPACITY]int
	records: [MAX_OUTPUT_FIELDS]i64
	cache_count, seen_count, record_count, cursor := 0, 0, 0, 2
	for _ in 0..<int(operation_count) {
		opcode, key, value := input[cursor], input[cursor+1], input[cursor+2]
		cursor += 3
		if key < -1_000_000 || key > 1_000_000 do return -1
		if opcode == 0 {
			if value < -1_000_000 || value > 1_000_000 do return -1
			for index in 0..<seen_count { if seen[index] == key do return -1 }
			seen[seen_count] = key
			seen_count += 1
			slot := cache_count
			if cache_count == capacity {
				slot = order[0]
				for index in 0..<(cache_count-1) { order[index] = order[index+1] }
				cache_count -= 1
			}
			keys[slot] = key
			values[slot] = value
			order[cache_count] = slot
			cache_count += 1
			append(&records[0], &record_count, 0)
			append(&records[0], &record_count, 0)
		} else if opcode == 1 {
			if value != 0 do return -1
			position := 0
			for position < cache_count && keys[order[position]] != key { position += 1 }
			if position == cache_count do return -1
			slot := order[position]
			cached_value := values[slot]
			for index in position..<(cache_count-1) { order[index] = order[index+1] }
			order[cache_count-1] = slot
			append(&records[0], &record_count, 1)
			append(&records[0], &record_count, 1)
			append(&records[0], &record_count, cached_value)
		} else {
			return -1
		}
	}
	append(&records[0], &record_count, 2)
	append(&records[0], &record_count, i64(cache_count))
	for index in 0..<cache_count {
		slot := order[index]
		append(&records[0], &record_count, keys[slot])
		append(&records[0], &record_count, values[slot])
	}
	output_bytes := record_count*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index in 0..<record_count { write_i64_le(output, index*8, records[index]) }
	return i64(output_bytes)
}
