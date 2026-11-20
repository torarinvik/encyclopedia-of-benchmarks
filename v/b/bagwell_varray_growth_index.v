struct Location {
	pointer_slot int
	child_base int
	element_offset int
}

fn level_start(level int) int {
	return if level == 0 { 0 } else if level == 1 { 64 } else { 320 }
}

fn locate(level int, index int) Location {
	value_start := level_start(level)
	side := if level == 0 { 8 } else if level == 1 { 16 } else { 32 }
	pointer_start := if level == 0 { 0 } else if level == 1 { 8 } else { 24 }
	relative := index - value_start
	child := relative / side
	return Location{pointer_start + child, value_start + child * side, relative % side}
}

fn find_level(index int, current_header int, previous_header [3]i64) int {
	mut level := current_header
	for level >= 0 && index < level_start(level) {
		level = int(previous_header[level])
	}
	return level
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'bagwell_varray_growth_index']
pub fn bagwell_varray_growth_index(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input) || length < 2 || length > 580 { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 0 || n_value > 321 || q_value < 0 || q_value > 256 { return -1 }
	n := int(n_value)
	q := int(q_value)
	if (n == 0 && q != 0) || length != usize(2 + n + q) { return -1 }
	query_start := 2 + n
	for j in 0 .. q {
		index := unsafe { input[query_start + j] }
		if index < 0 || index >= n_value { return -1 }
	}

	mut data := [352]i64{}
	mut pointers := [56]i64{}
	mut previous_header := [3]i64{init: -1}
	mut current_header := 0
	for i in 0 .. 56 { pointers[i] = -1 }
	for i in 0 .. n {
		if i == 64 || i == 320 {
			next_header := current_header + 1
			previous_header[next_header] = i64(current_header)
			current_header = next_header
		}
		location := locate(current_header, i)
		if pointers[location.pointer_slot] == -1 { pointers[location.pointer_slot] = i64(location.child_base) }
		if pointers[location.pointer_slot] != i64(location.child_base) || location.child_base + location.element_offset >= 352 { return -1 }
		data[int(pointers[location.pointer_slot]) + location.element_offset] = unsafe { input[2 + i] }
	}

	output_bytes := 8 * (q + 1)
	if isnil(output) || capacity < usize(output_bytes) { return -2 }
	put_i64_le(mut output, 0, q_value)
	for j in 0 .. q {
		index := int(unsafe { input[query_start + j] })
		level := find_level(index, current_header, previous_header)
		location := locate(level, index)
		base := int(pointers[location.pointer_slot])
		put_i64_le(mut output, 8 * (j + 1), data[base + location.element_offset])
	}
	return i64(output_bytes)
}
