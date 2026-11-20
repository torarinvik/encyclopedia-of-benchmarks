package apostolico_crochemore_search

import "core:c"

@(export)
apostolico_crochemore_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 4227 do return -1
	if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 do return -1
	text_length := int(input[0])
	pattern_length := int(input[1])
	pattern_start := 2 + text_length
	if length != c.size_t(2 + text_length + pattern_length) do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 3 do return -1
	}

	kmp_next: [129]int
	kmp_next[0] = -1
	preprocess_index := 0
	border := -1
	for preprocess_index < pattern_length {
		for border > -1 && input[pattern_start + preprocess_index] != input[pattern_start + border] {
			border = kmp_next[border]
		}
		preprocess_index += 1
		border += 1
		if preprocess_index < pattern_length && input[pattern_start + preprocess_index] == input[pattern_start + border] {
			kmp_next[preprocess_index] = kmp_next[border]
		} else {
			kmp_next[preprocess_index] = border
		}
	}

	ell := 1
	for ell < pattern_length && input[pattern_start + ell - 1] == input[pattern_start + ell] {
		ell += 1
	}
	if ell == pattern_length do ell = 0

	i, j, k := ell, 0, 0
	match_count: i64 = 0
	sum_offsets: i64 = 0
	xor_offsets: i64 = 0
	for j <= text_length - pattern_length {
		for i < pattern_length && input[pattern_start + i] == input[2 + j + i] {
			i += 1
		}
		if i >= pattern_length {
			for k < ell && input[pattern_start + k] == input[2 + j + k] {
				k += 1
			}
			if k >= ell {
				match_count += 1
				sum_offsets += i64(j)
				xor_offsets ~= i64(j)
			}
		}

		j += i - kmp_next[i]
		if i == ell {
			if k > 0 do k -= 1
		} else if kmp_next[i] <= ell {
			k = kmp_next[i]
			if k < 0 do k = 0
			i = ell
		} else {
			k = ell
			i = kmp_next[i]
		}
	}
	return match_count * 68_719_476_736 + sum_offsets * 4096 + xor_offsets
}
