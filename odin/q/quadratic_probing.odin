package quadratic_probing

import "core:c"

MIN_CAPACITY :: 5
MAX_CAPACITY :: 31
MAX_INSERT_COUNT :: 3
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(5)
MAX_OUTPUT_BYTES :: 256

quadratic_probing :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	capacity_value, count_value := input[0], input[1]
	if capacity_value < MIN_CAPACITY || capacity_value > MAX_CAPACITY || count_value < 0 || count_value > MAX_INSERT_COUNT do return -1
	capacity, insert_count := int(capacity_value), int(count_value)
	if input_length != c.size_t(2+insert_count) do return -1
	for index in 0..<insert_count { if input[index+2] < 0 do return -1 }

	var slots: [MAX_CAPACITY]i64
	for index in 0..<MAX_CAPACITY { slots[index] = -1 }
	for key_index in 0..<insert_count {
		key := input[key_index+2]
		home := int(key % i64(capacity))
		if slots[home] == -1 {
			slots[home] = key
			continue
		}
		if slots[home] == key do continue
		var visited: [MAX_CAPACITY]bool
		probe := 1
		for {
			slot := (home+probe*probe)%capacity
			if slots[slot] == -1 || slots[slot] == i64(home) {
				slots[slot] = key
				break
			}
			if visited[slot] do return -1
			visited[slot] = true
			probe += 1
		}
	}

	byte_length := 8*(capacity+1)
	if byte_length > MAX_OUTPUT_BYTES || output == nil || output_capacity < c.size_t(byte_length) do return -2
	var words: [MAX_CAPACITY+1]i64
	words[0] = i64(capacity)
	for index in 0..<capacity { words[index+1] = slots[index] }
	for word_index in 0..=capacity {
		bits := transmute(u64)words[word_index]
		for byte_index in 0..<8 { output[word_index*8+byte_index] = u8(bits >> u64(byte_index*8)) }
	}
	return i64(byte_length)
}
