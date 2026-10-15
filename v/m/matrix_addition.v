module matrix_addition

fn store_i32_le(mut output &u8, offset int, value u32) {
	for b in 0 .. 4 { unsafe { output[offset + b] = u8((value >> (b * 8)) & u32(255)) } }
}

@[export: 'matrix_addition']
pub fn matrix_addition(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 4 || unsafe { input == nil } { return -2 }
	unsafe {
		if input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 16 { return -2 }
		ra := int(input[0]); ca := int(input[1]); if ra == 0 && ca != 0 { return -2 }
		na := ra * ca; bd := 2 + na
		if bd + 2 > int(length) || input[bd] < 0 || input[bd] > 16 || input[bd + 1] < 0 || input[bd + 1] > 16 { return -2 }
		rb := int(input[bd]); cb := int(input[bd + 1]); if rb == 0 && cb != 0 { return -2 }
		nb := rb * cb; if int(length) != bd + 2 + nb { return -2 }
		if ra != rb || ca != cb { return -1 }
		for i in 0 .. na {
			if input[2 + i] < -2_147_483_648 || input[2 + i] > 2_147_483_647 || input[bd + 2 + i] < -2_147_483_648 || input[bd + 2 + i] > 2_147_483_647 { return -2 }
		}
		if na == 0 { return 0 }
		if output == nil || output_capacity < usize(na * 4) { return -3 }
		for i in 0 .. na {
			sum := u32(i32(input[2 + i])) + u32(i32(input[bd + 2 + i]))
			store_i32_le(mut output, i * 4, sum)
		}
		return i64(na)
	}
}
