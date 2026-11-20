module string_matching_ordered_alphabets

fn advance_maximal_suffix(input &i64, base int, segment_length int,
	mut left int, mut right int, mut offset int, mut period int) {
	unsafe {
		for right + offset < segment_length {
			a := input[base + left + offset]
			b := input[base + right + offset]
			if a == b {
				if offset == period { right += period; offset = 1 }
				else { offset++ }
			} else if a > b {
				right += offset
				offset = 1
				period = right - left
			} else {
				left = right
				right++
				offset = 1
				period = 1
			}
		}
	}
}

fn prefix_repeats(input &i64, base int, shift int, last_index int) bool {
	unsafe {
		for q in 0 .. last_index + 1 {
			if input[base + q] != input[base + shift + q] { return false }
		}
	}
	return true
}

@[export: 'string_matching_ordered_alphabets']
pub fn string_matching_ordered_alphabets(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 4227 { return -1 }
		if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		pattern_start := 2 + n
		for q in 0 .. n {
			if input[2 + q] < 0 || input[2 + q] > 3 { return -1 }
		}
		for q in 0 .. m {
			if input[pattern_start + q] < 0 || input[pattern_start + q] > 3 { return -1 }
		}
		if n < m { return 0 }

		mut alignment := 0
		mut matched := 0
		mut suffix_left := -1
		mut suffix_right := 0
		mut suffix_offset := 1
		mut period := 1
		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		for alignment <= n - m {
			for alignment + matched < n && matched < m &&
				input[pattern_start + matched] == input[2 + alignment + matched] {
				matched++
			}
			if matched == 0 {
				alignment++
				suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
				continue
			}
			if matched == m {
				count++
				offset_sum += i64(alignment)
				offset_xor ^= i64(alignment)
				if alignment == n - m { break }
			}

			base := 2 + alignment
			advance_maximal_suffix(input, base, matched + 1,
				mut suffix_left, mut suffix_right, mut suffix_offset, mut period)
			reusable := suffix_left < 0 ||
				(suffix_left < period && prefix_repeats(input, base, period, suffix_left))
			if reusable {
				alignment += period
				matched -= period
				if matched < 0 { matched = 0 }
				if suffix_right - suffix_left > period { suffix_right -= period }
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
}
