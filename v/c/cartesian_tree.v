module cartesian_tree

const max_n = 128

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'cartesian_tree']
pub fn cartesian_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(1 + max_n) { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }

	mut parent := []i64{len: max_n}
	mut stack := []int{len: max_n}
	for i in 0 .. n {
		key := unsafe { input[i + 1] }
		if key < 0 || key > 1_000_000_000 { return -1 }
		parent[i] = i64(i)
	}

	mut stack_size := 0
	for i in 0 .. n {
		mut last := max_n
		for stack_size > 0 && unsafe { input[stack[stack_size - 1] + 1] > input[i + 1] } {
			stack_size--
			last = stack[stack_size]
		}
		if stack_size > 0 { parent[i] = i64(stack[stack_size - 1]) }
		if last < max_n { parent[last] = i64(i) }
		stack[stack_size] = i
		stack_size++
	}

	output_bytes := n * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	for i in 0 .. n { store_i64_le(mut output, i * 8, parent[i]) }
	return i64(output_bytes)
}
