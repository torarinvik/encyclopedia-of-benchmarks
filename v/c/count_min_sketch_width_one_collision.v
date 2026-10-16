module count_min_sketch_width_one_collision

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'count_min_sketch_width_one_collision']
pub fn count_min_sketch_width_one_collision(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 513 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > 256 { return -1 }
	count := int(count_value)
	if length != usize(1 + count * 2) { return -1 }
	mut queries := 0
	unsafe {
		for i in 0 .. count {
			operation := input[1 + 2 * i]
			key := input[2 + 2 * i]
			if (operation != 0 && operation != 1) || key < -1_000_000 || key > 1_000_000 { return -1 }
			if operation == 1 { queries++ }
		}
	}
	required := queries * 8
	if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
	mut inserts := i64(0)
	mut output_offset := 0
	unsafe {
		for i in 0 .. count {
			if input[1 + 2 * i] == 0 { inserts++ }
			else { put_i64_le(mut output, output_offset, inserts); output_offset += 8 }
		}
	}
	return i64(required)
}
