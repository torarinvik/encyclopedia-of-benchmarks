module reverse_colussi_search

const max_text = 4096
const max_pattern = 128
const max_input_length = 4227

@[export: 'reverse_colussi_search']
pub fn reverse_colussi_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 0 || n64 > max_text || m64 < 1 || m64 > max_pattern { return -1 }
		n, m := int(n64), int(m64)
		if int(length) != 2+n+m { return -1 }
		mut text := [max_text]u8{}
		mut pattern := [max_pattern]u8{}
		for q in 0 .. n {
			value := input[2+q]
			if value < 0 || value > 3 { return -1 }
			text[q] = u8(value)
		}
		for q in 0 .. m {
			value := input[2+n+q]
			if value < 0 || value > 3 { return -1 }
			pattern[q] = u8(value)
		}
		if n < m { return 0 }

		mut hmin := [max_pattern+1]int{}
		mut kmin := [max_pattern]int{}
		mut rmin := [max_pattern]int{}
		mut order := [max_pattern]int{}
		mut good_suffix := [max_pattern+1]int{}
		mut bad_character := [4*(max_pattern+1)]int{}
		for shift := 1; shift <= m; shift++ {
			mut last_mismatch := shift-1
			for pos := shift; pos < m; pos++ {
				if pattern[pos] != pattern[pos-shift] { last_mismatch = pos }
			}
			hmin[shift] = last_mismatch
		}
		mut shift := m
		for shift > 0 {
			end := hmin[shift]
			if end != m-1 { kmin[end] = shift }
			shift--
		}
		mut next_boundary := m
		mut end := m-1
		for end >= 0 {
			if hmin[end+1] == end { next_boundary = end+1 }
			rmin[end] = next_boundary
			end--
		}

		order[0] = m-1
		mut cursor := 0
		for shift := 1; shift <= m; shift++ {
			h_end := hmin[shift]
			if h_end != m-1 && kmin[h_end] == shift {
				cursor++
				order[cursor] = h_end
				good_suffix[cursor] = shift
			}
		}
		cursor = m-1
		end = m-2
		for end >= 0 {
			if kmin[end] == 0 {
				order[cursor] = end
				good_suffix[cursor] = rmin[end]
				cursor--
			}
			end--
		}
		good_suffix[m] = rmin[0]

		for symbol := 0; symbol < 4; symbol++ {
			for prior_shift := 1; prior_shift <= m; prior_shift++ {
				boundary := m-prior_shift-1
				for candidate := 1; candidate <= m; candidate++ {
					if candidate < m && int(pattern[m-candidate-1]) != symbol { continue }
					if candidate <= boundary && pattern[m-candidate-prior_shift-1] != pattern[boundary] { continue }
					bad_character[symbol*(max_pattern+1)+prior_shift] = candidate
					break
				}
			}
		}

		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		mut start := 0
		mut shift_state := m
		last_start := n-m
		for start <= last_start {
			for start <= last_start && pattern[m-1] != text[start+m-1] {
				shift_state = bad_character[int(text[start+m-1])*(max_pattern+1)+shift_state]
				start += shift_state
			}
			if start > last_start { break }
			mut index := 1
			for index < m && pattern[order[index]] == text[start+order[index]] { index++ }
			if index == m {
				count++
				offset_sum += i64(start)
				offset_xor ^= i64(start)
			}
			shift_state = good_suffix[index]
			start += shift_state
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
