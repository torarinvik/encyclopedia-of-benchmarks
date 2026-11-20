package string_matching_ordered_alphabets

import "core:c"

advance_maximal_suffix :: proc "contextless" (input: [^]i64, base, segment_length: int,
		left, right, offset, period: ^int) {
	for right^ + offset^ < segment_length {
		a := input[base + left^ + offset^]
		b := input[base + right^ + offset^]
		if a == b {
			if offset^ == period^ { right^ += period^; offset^ = 1 }
			else { offset^ += 1 }
		} else if a > b {
			right^ += offset^
			offset^ = 1
			period^ = right^ - left^
		} else {
			left^ = right^
			right^ += 1
			offset^ = 1
			period^ = 1
		}
	}
}

prefix_repeats :: proc "contextless" (input: [^]i64, base, shift, last_index: int) -> bool {
	for q := 0; q <= last_index; q += 1 {
		if input[base + q] != input[base + shift + q] do return false
	}
	return true
}

@(export)
string_matching_ordered_alphabets :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 4227 do return -1
	if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 do return -1
	n := int(input[0])
	m := int(input[1])
	if length != c.size_t(2 + n + m) do return -1
	pattern_start := 2 + n
	for q := 0; q < n; q += 1 {
		if input[2 + q] < 0 || input[2 + q] > 3 do return -1
	}
	for q := 0; q < m; q += 1 {
		if input[pattern_start + q] < 0 || input[pattern_start + q] > 3 do return -1
	}
	if n < m do return 0

	alignment := 0
	matched := 0
	suffix_left := -1
	suffix_right := 0
	suffix_offset := 1
	period := 1
	count: i64 = 0
	offset_sum: i64 = 0
	offset_xor: i64 = 0
	for alignment <= n - m {
		for alignment + matched < n && matched < m && input[pattern_start + matched] == input[2 + alignment + matched] {
			matched += 1
		}
		if matched == 0 {
			alignment += 1
			suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
			continue
		}
		if matched == m {
			count += 1
			offset_sum += i64(alignment)
			offset_xor ^= i64(alignment)
			if alignment == n - m do break
		}

		base := 2 + alignment
		advance_maximal_suffix(input, base, matched + 1,
			&suffix_left, &suffix_right, &suffix_offset, &period)
		reusable := suffix_left < 0 ||
			(suffix_left < period && prefix_repeats(input, base, period, suffix_left))
		if reusable {
			alignment += period
			matched -= period
			if matched < 0 do matched = 0
			if suffix_right - suffix_left > period do suffix_right -= period
			else { suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1 }
		} else {
			conservative := min(matched - suffix_left - 1, suffix_right + 1)
			certified := max(suffix_left + 1, conservative)
			alignment += certified + 1
			matched = 0
			suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
		}
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
