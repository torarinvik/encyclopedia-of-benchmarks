package distinct_substring_count_hashing

import "core:c"

@(export)
distinct_substring_count_hashing :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 66 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > 64 || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	for i := 0; i < n; i += 1 { if input[i + 1] < 0 || input[i + 1] > 255 do return -1 }

	prefix: [65]i64
	powers: [65]i64
	powers[0] = 1
	for i := 0; i < n; i += 1 {
		prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) % 1_000_000_007
		powers[i + 1] = powers[i] * 257 % 1_000_000_007
	}
	group_hash: [64]i64
	group_head: [64]i64
	representative_start: [64]i64
	representative_next: [64]i64
	distinct := i64(0)
	for width := 1; width <= n; width += 1 {
		for slot := 0; slot < 64; slot += 1 { group_hash[slot] = -1; group_head[slot] = -1 }
		representative_count := 0
		for start := 0; start + width <= n; start += 1 {
			end := start + width
			fingerprint := (prefix[end] - prefix[start] * powers[width] % 1_000_000_007) % 1_000_000_007
			if fingerprint < 0 { fingerprint += 1_000_000_007 }
			slot := int(fingerprint % 64)
			for group_hash[slot] != -1 && group_hash[slot] != fingerprint { slot = (slot + 1) % 64 }
			if group_hash[slot] == -1 { group_hash[slot] = fingerprint }
			duplicate := false
			prior := group_head[slot]
			for prior >= 0 {
				old_start := int(representative_start[int(prior)])
				offset := 0
				for offset < width && input[start + offset + 1] == input[old_start + offset + 1] { offset += 1 }
				if offset == width { duplicate = true; break }
				prior = representative_next[int(prior)]
			}
			if !duplicate {
				representative_start[representative_count] = i64(start)
				representative_next[representative_count] = group_head[slot]
				group_head[slot] = i64(representative_count)
				representative_count += 1
				distinct += 1
			}
		}
	}
	return distinct
}
