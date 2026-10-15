module next_smaller_element

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 {
		unsafe { output[offset+b] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'next_smaller_element']
pub fn next_smaller_element(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		n64 := input[0]
		if n64 < 0 || n64 > 1024 || length != usize(n64)+1 { return -1 }
		n := int(n64)
		for i in 0 .. n { if input[i+1] < -2147483648 || input[i+1] > 2147483647 { return -1 } }
		if capacity < n*8 || (n > 0 && output == nil) { return -2 }
		mut stack := []i64{len: 1024, init: 0}
		mut top := 0
		for i in 0 .. n {
			value := input[i+1]
			for top > 0 && stack[top-1] >= value { top-- }
			mut previous := i64(-1)
			if top > 0 { previous = stack[top-1] }
			put_i64_le(mut output, i*8, previous)
			stack[top] = value
			top++
		}
		return i64(n*8)
	}
}
