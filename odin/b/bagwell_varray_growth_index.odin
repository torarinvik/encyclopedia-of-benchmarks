package bagwell_varray_growth_index

import "core:c"

Location :: struct { pointer_slot: usize, child_base: usize, element_offset: usize }

level_start :: proc "contextless" (level: usize) -> usize {
	starts := [3]usize{0, 64, 320}
	return starts[level]
}

locate :: proc "contextless" (level, index: usize) -> Location {
	value_start := level_start(level)
	side := usize(8)
	pointer_start := usize(0)
	if level == 1 { side, pointer_start = 16, 8 }
	else if level == 2 { side, pointer_start = 32, 24 }
	relative := index - value_start
	child := relative / side
	return Location{pointer_start + child, value_start + child * side, relative % side}
}

find_level :: proc "contextless" (index, current_header: usize, previous_header: [3]i64) -> i64 {
	level := i64(current_header)
	for level >= 0 && index < level_start(usize(level)) {
		level = previous_header[usize(level)]
	}
	return level
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
bagwell_varray_growth_index :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 580 { return -1 }
	n_value, q_value := input[0], input[1]
	if n_value < 0 || n_value > 321 || q_value < 0 || q_value > 256 { return -1 }
	n, q := usize(n_value), usize(q_value)
	if (n == 0 && q != 0) || length != c.size_t(2 + n + q) { return -1 }
	query_start := 2 + n
	for j := usize(0); j < q; j += 1 {
		index := input[query_start + j]
		if index < 0 || index >= n_value { return -1 }
	}

	data: [352]i64
	pointers: [56]i64
	previous_header: [3]i64 = {-1, -1, -1}
	current_header := usize(0)
	for i := 0; i < 56; i += 1 { pointers[i] = -1 }
	for i := usize(0); i < n; i += 1 {
		if i == 64 || i == 320 {
			next_header := current_header + 1
			previous_header[next_header] = i64(current_header)
			current_header = next_header
		}
		location := locate(current_header, i)
		if pointers[location.pointer_slot] == -1 { pointers[location.pointer_slot] = i64(location.child_base) }
		if pointers[location.pointer_slot] != i64(location.child_base) || location.child_base + location.element_offset >= 352 { return -1 }
		data[usize(pointers[location.pointer_slot]) + location.element_offset] = input[2 + i]
	}

	output_bytes := 8 * (q + 1)
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }
	put_i64_le(output, 0, q_value)
	for j := usize(0); j < q; j += 1 {
		index := usize(input[query_start + j])
		level := find_level(index, current_header, previous_header)
		location := locate(usize(level), index)
		base := usize(pointers[location.pointer_slot])
		put_i64_le(output, 8 * (j + 1), data[base + location.element_offset])
	}
	return i64(output_bytes)
}
