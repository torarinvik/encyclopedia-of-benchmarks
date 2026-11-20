module kmp_skip_search

const max_text = 4096
const max_pattern = 128
const max_input_length = 4227

@[export: 'kmp_skip_search']
pub fn kmp_skip_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 0 || n64 > max_text || m64 < 1 || m64 > max_pattern { return -1 }
		n, m := int(n64), int(m64)
		if int(length) != 2+n+m { return -1 }
		mut text := [max_text]u8{}
		mut pattern := [max_pattern]u8{}
		for q in 0 .. n {
			symbol := input[2+q]
			if symbol < 0 || symbol > 3 { return -1 }
			text[q] = u8(symbol)
		}
		for q in 0 .. m {
			symbol := input[2+n+q]
			if symbol < 0 || symbol > 3 { return -1 }
			pattern[q] = u8(symbol)
		}
		if n < m { return 0 }

		mut mp_next := [max_pattern+1]int{}
		mut kmp_next := [max_pattern+1]int{}
		mut q := 0
		mut border := -1
		mp_next[0] = -1
		for q < m {
			for border >= 0 && pattern[q] != pattern[border] { border = mp_next[border] }
			q++
			border++
			mp_next[q] = border
		}
		q = 0
		border = -1
		kmp_next[0] = -1
		for q < m {
			for border >= 0 && pattern[q] != pattern[border] { border = kmp_next[border] }
			q++
			border++
			if q < m && pattern[q] == pattern[border] { kmp_next[q] = kmp_next[border] }
			else { kmp_next[q] = border }
		}

		mut last := [4]int{init: -1}
		mut previous := [max_pattern]int{}
		for q in 0 .. m {
			symbol := int(pattern[q])
			previous[q] = last[symbol]
			last[symbol] = q
		}

		mut sample := -1
		mut i := -1
		for {
			sample += m
			if sample >= n { return 0 }
			i = last[int(text[sample])]
			if i >= 0 { break }
		}
		mut start := sample-i
		mut wall := 0
		period := m-kmp_next[m]
		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		for start <= n-m {
			if start > wall { wall = start }
			mut k := wall-start
			for k < m && pattern[k] == text[start+k] { k++ }
			wall = start+k
			if k == m {
				count++
				offset_sum += i64(start)
				offset_xor ^= i64(start)
				i -= period
			} else {
				i = previous[i]
			}
			if i < 0 {
				mut found := false
				for {
					sample += m
					if sample >= n { break }
					i = last[int(text[sample])]
					if i >= 0 { found = true; break }
				}
				if !found { break }
			}

			mut kmp_start := start+k-kmp_next[k]
			k = kmp_next[k]
			start = sample-i
			for start < kmp_start || (kmp_start < start && start < wall) {
				if start < kmp_start {
					i = previous[i]
					if i < 0 {
						mut found := false
						for {
							sample += m
							if sample >= n { break }
							i = last[int(text[sample])]
							if i >= 0 { found = true; break }
						}
						if !found { return (count << 36) | (offset_sum << 12) | offset_xor }
					}
					start = sample-i
				} else {
					kmp_start += k-mp_next[k]
					k = mp_next[k]
				}
			}
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
