module morris_pratt_search

@[export: 'morris_pratt_search']
pub fn morris_pratt_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 4227 { return -1 }
		if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		pattern_start := 2 + n
		for q in 0 .. n + m {
			if input[2 + q] < 0 || input[2 + q] > 3 { return -1 }
		}

		mut mp_next := [129]i64{}
		mp_next[0] = -1
		for index in 0 .. m {
			mut border := int(mp_next[index])
			for border >= 0 && input[pattern_start + index] != input[pattern_start + border] {
				border = int(mp_next[border])
			}
			mp_next[index + 1] = i64(border + 1)
		}

		mut matched := 0
		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		for text_index in 0 .. n {
			for matched >= 0 && input[pattern_start + matched] != input[2 + text_index] {
				matched = int(mp_next[matched])
			}
			matched++
			if matched == m {
				start := i64(text_index + 1 - matched)
				count++
				offset_sum += start
				offset_xor ^= start
				matched = int(mp_next[m])
			}
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
