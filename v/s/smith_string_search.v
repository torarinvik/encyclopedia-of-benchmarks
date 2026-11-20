module smith_string_search

@[export: 'smith_string_search']
pub fn smith_string_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
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
			pattern_start := 2 + n
			mut horspool := [128]int{}
			mut quick_search := [128]int{}
			for byte in 0 .. 128 {
				horspool[byte] = m
				quick_search[byte] = m + 1
			}
			for i in 0 .. m - 1 { horspool[int(input[pattern_start + i])] = m - i - 1 }
			for i in 0 .. m { quick_search[int(input[pattern_start + i])] = m - i }
			mut alignment := 0
			last_alignment := n - m
			for alignment <= last_alignment {
				mut matches := true
				for i in 0 .. m {
					if input[pattern_start + i] != input[2 + alignment + i] { matches = false; break }
				}
				if matches {
					positions[match_count] = i64(alignment)
					match_count++
				}
				end_byte := int(input[2 + alignment + m - 1])
				lookahead := alignment + m
				mut quick_shift := m + 1
				if lookahead < n { quick_shift = quick_search[int(input[2 + lookahead])] }
				end_shift := horspool[end_byte]
				if end_shift > quick_shift { alignment += end_shift } else { alignment += quick_shift }
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
