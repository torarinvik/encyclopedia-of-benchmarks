module composite_lfsr_majority_clock

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 0xff) }
		bits >>= 8
	}
}

@[export: 'composite_lfsr_majority_clock']
pub fn composite_lfsr_majority_clock(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 3 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 524287 || input[1] < 0 || input[1] > 4194303 || input[2] < 0 || input[2] > 8388607 { return -1 }
		if output == nil || output_capacity < 32 { return -2 }
		mut s1 := u64(input[0]); mut s2 := u64(input[1]); mut s3 := u64(input[2])
		c1 := (s1 >> 8) & 1; c2 := (s2 >> 10) & 1; c3 := (s3 >> 10) & 1
		majority := c1 + c2 + c3 >= 2
		emitted := ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1
		if (c1 == 1) == majority { s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1) }
		if (c2 == 1) == majority { s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ^ (s2 >> 21)) & 1) }
		if (c3 == 1) == majority { s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1) }
		write_i64_le(mut output, 0, i64(emitted)); write_i64_le(mut output, 8, i64(s1))
		write_i64_le(mut output, 16, i64(s2)); write_i64_le(mut output, 24, i64(s3))
		return 32
	}
}
