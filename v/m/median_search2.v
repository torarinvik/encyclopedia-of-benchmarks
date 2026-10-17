module median_search2

const max_nodes = 128
const max_input_length = 129

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'median_search2']
pub fn median_search2(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_nodes { return -1 }
		count := int(input[0])
		if int(length) != count + 1 { return -1 }
		for i in 0 .. count {
			if input[i + 1] < -2147483648 || input[i + 1] > 2147483647 { return -1 }
		}

		mut next := [max_nodes]i32{}
		for i in 0 .. count {
			if i + 1 < count { next[i] = i32(i + 1) }
			else { next[i] = -1 }
		}
		mut found := i32(0)
		mut median_index := i32(-1)
		if count > 0 {
			mut slow := i32(0)
			mut fast := i32(0)
			for next[int(fast)] >= 0 && next[int(next[int(fast)])] >= 0 {
				slow = next[int(slow)]
				fast = next[int(next[int(fast)])]
			}
			if next[int(fast)] >= 0 { median_index = next[int(slow)] }
			else { median_index = slow }
			found = 1
		}
		if output == nil || capacity < 8 { return -2 }
		mut buffer := [8]u8{}
		put_i32_le(mut buffer[0], 0, found)
		put_i32_le(mut buffer[0], 4, median_index)
		for i in 0 .. 8 { output[i] = buffer[i] }
		return 8
	}
}
