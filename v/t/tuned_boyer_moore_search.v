module tuned_boyer_moore_search

@[export: 'tuned_boyer_moore_search']
pub fn tuned_boyer_moore_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 322 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 255 || input[1] < 1 || input[1] > 64 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		for i in 0 .. n + m {
			if input[2 + i] < 0 || input[2 + i] > 127 { return -1 }
		}
		mut positions := [255]i64{}
		mut match_count := 0
		if m <= n {
			mut padded := [319]u8{}
			mut shifts := [128]int{}
			pattern_start := 2 + n
			final_byte := u8(input[pattern_start + m - 1])
			for i in 0 .. n { padded[i] = u8(input[2 + i]) }
			for i in 0 .. m { padded[n + i] = final_byte }
			for byte in 0 .. 128 { shifts[byte] = m }
			for i in 0 .. m - 1 { shifts[int(input[pattern_start + i])] = m - i - 1 }
			final_shift := shifts[int(final_byte)]
			shifts[int(final_byte)] = 0
			mut alignment := 0
			for alignment < n {
				mut skip := shifts[int(padded[alignment + m - 1])]
				for skip != 0 {
					alignment += skip
					skip = shifts[int(padded[alignment + m - 1])]
					alignment += skip
					skip = shifts[int(padded[alignment + m - 1])]
					alignment += skip
					skip = shifts[int(padded[alignment + m - 1])]
				}
				mut prefix_matches := true
				for i in 0 .. m - 1 {
					if input[pattern_start + i] != i64(padded[alignment + i]) { prefix_matches = false; break }
				}
				if prefix_matches && alignment < n {
					positions[match_count] = i64(alignment)
					match_count++
				}
				alignment += final_shift
			}
		}
		output_bytes := match_count * 8
		if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. match_count {
			bits := u64(positions[i])
			for byte in 0 .. 8 {
				unsafe { output[i * 8 + byte] = u8(bits & 255) }
				bits >>= 8
			}
		}
		return i64(output_bytes)
	}
}
