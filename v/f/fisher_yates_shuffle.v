module fisher_yates_shuffle

@[export: 'fisher_yates_shuffle']
pub fn fisher_yates_shuffle(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	max_values := 1024
	modulus := u64(2_147_483_647)
	if unsafe { input == nil } || length < 1 || length > usize(max_values + 1) { return -1 }
	seed := unsafe { input[0] }
	if seed < 1 || seed >= 2_147_483_647 { return -1 }
	count := int(length - 1)
	mut values := []i32{len: max_values}
	for i in 0 .. count {
		value := unsafe { input[i + 1] }
		if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
		values[i] = i32(value)
	}
	byte_count := usize(count * 4)
	if output_capacity < byte_count || (byte_count != 0 && unsafe { output == nil }) { return -2 }
	mut state := u64(seed)
	mut remaining := count
	for remaining >= 2 {
		state = (state * u64(48_271)) % modulus
		other := int(state % u64(remaining))
		temporary := values[remaining - 1]
		values[remaining - 1] = values[other]
		values[other] = temporary
		remaining--
	}
	for i in 0 .. count {
		bits := u32(values[i])
		for byte in 0 .. 4 {
			unsafe { output[i * 4 + byte] = u8((bits >> u32(byte * 8)) & 255) }
		}
	}
	return i64(count)
}
