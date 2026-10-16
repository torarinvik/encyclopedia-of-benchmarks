module generate_subsets_recursive

const max_items = 12

fn generate_subsets_recursive_put32(mut output &u8, mut pos int, value u32) {
	mut bits := value
	for _ in 0 .. 4 { unsafe { output[pos] = u8(bits & 255) }; pos++; bits >>= 8 }
}

fn generate_subsets_recursive_emit(input &i64, n int, index int, mask u32, selected u32,
	mut output &u8, mut pos int) {
	if index == n {
		generate_subsets_recursive_put32(mut output, mut pos, selected)
		for i in 0 .. n {
			if (mask & (u32(1) << i)) != 0 { unsafe { output[pos] = u8(input[i + 1]) }; pos++ }
		}
		return
	}
	generate_subsets_recursive_emit(input, n, index + 1, mask | (u32(1) << index), selected + 1, mut output, mut pos)
	generate_subsets_recursive_emit(input, n, index + 1, mask, selected, mut output, mut pos)
}

@[export: 'generate_subsets_recursive']
pub fn generate_subsets_recursive(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_items + 1 { return -1 }
	n_arg := unsafe { input[0] }
	if n_arg < 0 || n_arg > max_items { return -1 }
	n := int(n_arg)
	if length != usize(n + 1) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value > 127 { return -1 }
	}
	subsets := 1 << n
	needed := 4 + 4 * subsets + n * (subsets / 2)
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	mut pos := 0
	generate_subsets_recursive_put32(mut output, mut pos, u32(subsets))
	generate_subsets_recursive_emit(input, n, 0, 0, 0, mut output, mut pos)
	return i64(pos)
}
