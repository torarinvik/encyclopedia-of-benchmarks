module revert_bits

const output_bytes = 12

fn reverse_bits32(value u32) u32 {
	mut n := value
	n = ((n >> 1) & u32(0x55555555)) | ((n & u32(0x55555555)) << 1)
	n = ((n >> 2) & u32(0x33333333)) | ((n & u32(0x33333333)) << 2)
	n = ((n >> 4) & u32(0x0f0f0f0f)) | ((n & u32(0x0f0f0f0f)) << 4)
	return ((n & u32(0xff000000)) >> 24) | ((n & u32(0x00ff0000)) >> 8) |
		((n & u32(0x0000ff00)) << 8) | ((n & u32(0x000000ff)) << 24)
}

fn reverse_bits64(value u64) u64 {
	mut n := value
	n = ((n >> 1) & u64(0x5555555555555555)) | ((n & u64(0x5555555555555555)) << 1)
	n = ((n >> 2) & u64(0x3333333333333333)) | ((n & u64(0x3333333333333333)) << 2)
	n = ((n >> 4) & u64(0x0f0f0f0f0f0f0f0f)) | ((n & u64(0x0f0f0f0f0f0f0f0f)) << 4)
	return ((n & u64(0xff00000000000000)) >> 56) | ((n & u64(0x00ff000000000000)) >> 40) |
		((n & u64(0x0000ff0000000000)) >> 24) | ((n & u64(0x000000ff00000000)) >> 8) |
		((n & u64(0x00000000ff000000)) << 8) | ((n & u64(0x0000000000ff0000)) << 24) |
		((n & u64(0x000000000000ff00)) << 40) | ((n & u64(0x00000000000000ff)) << 56)
}

@[export: 'revert_bits']
pub fn revert_bits(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 4_294_967_295 { return -1 }
		if output == nil || capacity < output_bytes { return -2 }
		reversed32 := reverse_bits32(u32(input[0]))
		reversed64 := reverse_bits64(u64(input[1]))
		for i in 0 .. 4 { output[i] = u8((reversed32 >> u32(8 * i)) & 0xff) }
		for i in 0 .. 8 { output[4 + i] = u8((reversed64 >> u64(8 * i)) & 0xff) }
		return output_bytes
	}
}
