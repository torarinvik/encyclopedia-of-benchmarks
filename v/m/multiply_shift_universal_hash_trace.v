module multiply_shift_universal_hash_trace

const max_queries = 32
const word_mask = u64(0xffff_ffff)

@[export: 'multiply_shift_universal_hash_trace']
pub fn multiply_shift_universal_hash_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
	width := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if width < 1 || width > 16 || count_value < 0 || count_value > max_queries { return -1 }
	count := int(count_value)
	if length != usize(2 + 2 * count) { return -1 }

	for query in 0 .. count {
		multiplier := unsafe { input[2 + 2 * query] }
		key := unsafe { input[3 + 2 * query] }
		if multiplier < 1 || multiplier > 4294967295 || (multiplier & 1) == 0 { return -1 }
		if key < 0 || key > 4294967295 { return -1 }
	}

	required := count * 8
	if (required > 0 && unsafe { output == nil }) || capacity < usize(required) { return -2 }
	shift := u32(32 - int(width))
	for query in 0 .. count {
		multiplier := u64(unsafe { input[2 + 2 * query] })
		key := u64(unsafe { input[3 + 2 * query] })
		value := ((multiplier * key) & word_mask) >> shift
		for byte in 0 .. 8 { unsafe { output[query * 8 + byte] = u8(value >> u32(8 * byte)) } }
	}
	return i64(required)
}
