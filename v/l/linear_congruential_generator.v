module linear_congruential_generator

fn put_u64_le(mut output &u8, offset int, value u64) {
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(value >> u64(byte * 8)) } }
}

@[export: 'linear_congruential_generator']
pub fn linear_congruential_generator(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 5 { return -1 }
	seed := unsafe { input[0] }; multiplier := unsafe { input[1] }; increment := unsafe { input[2] }; modulo := unsafe { input[3] }; count := unsafe { input[4] }
	if modulo < 2 || modulo > 4294967296 || seed < 0 || seed >= modulo || multiplier < 0 || multiplier > 65535 || increment < 0 || increment > 4294967295 || count < 0 || count > 512 { return -1 }
	n := int(count); required := n * 8
	if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
	mut state := u64(seed)
	for i in 0 .. n { state = (u64(multiplier) * state + u64(increment)) % u64(modulo); put_u64_le(mut output, i * 8, state) }
	return i64(required)
}
