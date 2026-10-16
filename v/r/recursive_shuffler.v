module recursive_shuffler

fn shuffle_recursive(mut values []i32, item int, state u64) u64 {
	if item <= 0 { return state }
	mut next_state := shuffle_recursive(mut values, item - 1, state)
	next_state = (next_state * u64(48_271)) % u64(2_147_483_647)
	other := int(next_state % u64(item + 1))
	temporary := values[item]
	values[item] = values[other]
	values[other] = temporary
	return next_state
}

@[export: 'recursive_shuffler']
pub fn recursive_shuffler(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 65 { return -1 }
	seed := unsafe { input[0] }
	if seed < 1 || seed >= 2_147_483_647 { return -1 }
	count := int(length - 1)
	mut values := []i32{len: count}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
		values[index] = i32(value)
	}
	byte_count := usize(count * 4)
	if output_capacity < byte_count || (byte_count != 0 && unsafe { output == nil }) { return -2 }
	if count > 1 { _ = shuffle_recursive(mut values, count - 1, u64(seed)) }
	for index in 0 .. count {
		bits := u32(values[index])
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255) }
		}
	}
	return i64(count)
}
