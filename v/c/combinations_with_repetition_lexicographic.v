module combinations_with_repetition_lexicographic

fn multiset_count(n int, r int) int {
	if r == 0 { return 1 }
	if n == 0 { return 0 }
	top := n + r - 1
	mut result := 1
	for index in 1 .. r + 1 { result = result * (top - r + index) / index }
	return result
}

@[export: 'combinations_with_repetition_lexicographic']
pub fn combinations_with_repetition_lexicographic(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	n_word := unsafe { input[0] }
	r_word := unsafe { input[1] }
	if n_word < 0 || n_word > 4 || r_word < 0 || r_word > 4 { return -1 }
	n := int(n_word)
	r := int(r_word)
	count := multiset_count(n, r)
	byte_count := 2 + count * r
	if unsafe { output == nil } || capacity < usize(byte_count) { return -2 }

	unsafe {
		output[0] = u8(count & 255)
		output[1] = u8((count >> 8) & 255)
	}
	mut current := [4]u8{}
	for ordinal in 0 .. count {
		for position in 0 .. r {
			unsafe { output[2 + ordinal * r + position] = current[position] }
		}
		if ordinal + 1 < count && r > 0 {
			mut position := r
			for int(current[position - 1]) == n - 1 { position-- }
			position--
			current[position]++
			for suffix in position + 1 .. r { current[suffix] = current[position] }
		}
	}
	return i64(byte_count)
}
