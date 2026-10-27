@[export: 'pfr_local_forward_decision']
pub fn pfr_local_forward_decision(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		angle, draw := input[0], input[1]
		if angle < 0 || angle > 180000000 || draw < 0 || draw >= 1000000 { return -1 }
		forward := if angle >= 134000000 || 180 * draw < angle { i64(1) } else { i64(0) }
		if output == nil || capacity < 8 { return -2 }
		bits := u64(forward)
		for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
		return 8
	}
}
