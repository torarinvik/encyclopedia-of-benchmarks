module distinct_substring_count_hashing

@[export: 'distinct_substring_count_hashing']
pub fn distinct_substring_count_hashing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 66 { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > 64 || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] > 255 { return -1 } }

		mut prefix := [65]i64{}
		mut powers := [65]i64{}
		powers[0] = 1
		for i in 0 .. n {
			prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) % 1000000007
			powers[i + 1] = powers[i] * 257 % 1000000007
		}
		mut group_hash := [64]i64{}
		mut group_head := [64]i64{}
		mut representative_start := [64]i64{}
		mut representative_next := [64]i64{}
		mut distinct := i64(0)
		for width in 1 .. n + 1 {
			for slot in 0 .. 64 { group_hash[slot] = -1; group_head[slot] = -1 }
			mut representative_count := 0
			for start in 0 .. n - width + 1 {
				end := start + width
				mut fingerprint := (prefix[end] - prefix[start] * powers[width] % 1000000007) % 1000000007
				if fingerprint < 0 { fingerprint += 1000000007 }
				mut slot := int(fingerprint % 64)
				for group_hash[slot] != -1 && group_hash[slot] != fingerprint { slot = (slot + 1) % 64 }
				if group_hash[slot] == -1 { group_hash[slot] = fingerprint }
				mut duplicate := false
				mut prior := group_head[slot]
				for prior >= 0 {
					old_start := int(representative_start[int(prior)])
					mut offset := 0
					for offset < width && input[start + offset + 1] == input[old_start + offset + 1] { offset++ }
					if offset == width { duplicate = true; break }
					prior = representative_next[int(prior)]
				}
				if !duplicate {
					representative_start[representative_count] = i64(start)
					representative_next[representative_count] = group_head[slot]
					group_head[slot] = i64(representative_count)
					representative_count++
					distinct++
				}
			}
		}
		return distinct
	}
}
