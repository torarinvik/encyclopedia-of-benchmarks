module skip_search

@[export: 'skip_search']
pub fn skip_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 4227 { return -1 }
		if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }

		mut text := [4096]u8{}
		mut pattern := [128]u8{}
		for q in 0 .. n {
			value := input[2 + q]
			if value < 0 || value > 3 { return -1 }
			text[q] = u8(value)
		}
		mut positions := [4][128]int{}
		mut bucket_sizes := [4]int{}
		for q in 0 .. m {
			value := input[2 + n + q]
			if value < 0 || value > 3 { return -1 }
			symbol := int(value)
			pattern[q] = u8(value)
			positions[symbol][bucket_sizes[symbol]] = q
			bucket_sizes[symbol]++
		}

		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		mut sample := m - 1
		for sample < n {
			symbol := int(text[sample])
			for item in 0 .. bucket_sizes[symbol] {
				start := sample - positions[symbol][item]
				if start < 0 || start > n - m { continue }
				mut matched := 0
				for matched < m && text[start + matched] == pattern[matched] { matched++ }
				if matched == m {
					count++
					offset_sum += i64(start)
					offset_xor ^= i64(start)
				}
			}
			sample += m
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
