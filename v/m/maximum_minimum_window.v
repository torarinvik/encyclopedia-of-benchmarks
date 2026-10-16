@[export: 'maximum_minimum_window']
fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset + b] = u8((bits >> (8 * b)) & 255) } }
}

@[export: 'maximum_minimum_window']
pub fn maximum_minimum_window(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -2 }
	unsafe {
		n0 := input[0]
		if n0 < 1 || n0 > 256 || int(length) != int(n0) + 1 { return -2 }
		n := int(n0)
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] > 1_000_000 { return -2 } }
		if output == nil || output_capacity < usize(n * 8) { return -3 }
		mut stack := []int{cap: n}
		mut left := []int{len: n, init: -1}
		mut right := []int{len: n, init: n}
		mut answer := []i64{len: n + 1}
		for i in 0 .. n {
			for stack.len > 0 && input[stack[stack.len - 1] + 1] >= input[i + 1] { stack.delete_last() }
			if stack.len > 0 { left[i] = stack[stack.len - 1] }
			stack << i
		}
		stack.clear()
		for ii in 0 .. n {
			i := n - 1 - ii
			for stack.len > 0 && input[stack[stack.len - 1] + 1] >= input[i + 1] { stack.delete_last() }
			if stack.len > 0 { right[i] = stack[stack.len - 1] }
			stack << i
		}
		for i in 0 .. n {
			size := right[i] - left[i] - 1
			if answer[size] < input[i + 1] { answer[size] = input[i + 1] }
		}
		for ii in 0 .. n - 1 {
			k := n - 1 - ii
			if answer[k] < answer[k + 1] { answer[k] = answer[k + 1] }
		}
		for i in 1 .. n + 1 {
			store_i64_le(mut output, (i - 1) * 8, answer[i])
		}
		return i64(n)
	}
}
