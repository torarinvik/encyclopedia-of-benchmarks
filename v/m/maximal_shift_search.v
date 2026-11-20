module maximal_shift_search

const max_text = 4096
const max_pattern = 128
const max_input_length = 4227
const alphabet = 4

fn ms_match_shift(pattern []u8, order_loc []int, order_symbol []int,
		m int, prefix_length int, initial_shift int) int {
	mut shift := initial_shift
	for shift < m {
		mut order_index := prefix_length - 1
		for order_index >= 0 {
			pattern_index := order_loc[order_index] - shift
			if pattern_index >= 0 && order_symbol[order_index] != int(pattern[pattern_index]) { break }
			order_index--
		}
		if order_index < 0 { break }
		shift++
	}
	return shift
}

@[export: 'maximal_shift_search']
pub fn maximal_shift_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 0 || n64 > max_text || m64 < 1 || m64 > max_pattern { return -1 }
		n, m := int(n64), int(m64)
		if int(length) != 2+n+m { return -1 }
		mut text := []u8{len: max_text}
		mut pattern := []u8{len: max_pattern}
		for q in 0 .. n {
			value := input[2+q]
			if value < 0 || value >= alphabet { return -1 }
			text[q] = u8(value)
		}
		for q in 0 .. m {
			value := input[2+n+q]
			if value < 0 || value >= alphabet { return -1 }
			pattern[q] = u8(value)
		}
		if n < m { return 0 }

		mut leading_shift := []int{len: max_pattern}
		mut order_loc := []int{len: max_pattern + 1}
		mut order_symbol := []int{len: max_pattern + 1}
		mut quick_shift := []int{len: alphabet}
		mut adapted_shift := []int{len: max_pattern + 1}
		for i in 0 .. m {
			mut previous := i - 1
			for previous >= 0 && pattern[previous] != pattern[i] { previous-- }
			leading_shift[i] = i - previous
			mut position := i
			for position > 0 {
				prior_loc := order_loc[position - 1]
				if leading_shift[prior_loc] > leading_shift[i] ||
					(leading_shift[prior_loc] == leading_shift[i] && prior_loc > i) { break }
				order_loc[position] = prior_loc
				position--
			}
			order_loc[position] = i
		}
		for i in 0 .. m { order_symbol[i] = int(pattern[order_loc[i]]) }
		order_loc[m] = m
		order_symbol[m] = -1
		for symbol in 0 .. alphabet { quick_shift[symbol] = m + 1 }
		for i in 0 .. m { quick_shift[int(pattern[i])] = m - i }

		mut shift := 1
		adapted_shift[0] = 1
		for prefix_length in 1 .. m + 1 {
			shift = ms_match_shift(pattern, order_loc, order_symbol, m, prefix_length, shift)
			adapted_shift[prefix_length] = shift
		}
		for prefix_length in 0 .. m + 1 {
			shift = adapted_shift[prefix_length]
			for shift < m {
				pattern_index := order_loc[prefix_length] - shift
				if pattern_index < 0 || order_symbol[prefix_length] != int(pattern[pattern_index]) { break }
				shift++
				shift = ms_match_shift(pattern, order_loc, order_symbol, m, prefix_length, shift)
			}
			adapted_shift[prefix_length] = shift
		}

		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		mut start := 0
		for start <= n-m {
			mut compared := 0
			for compared < m && order_symbol[compared] == int(text[start+order_loc[compared]]) { compared++ }
			if compared == m {
				count++
				offset_sum += i64(start)
				offset_xor ^= i64(start)
			}
			lookahead := start + m
			if lookahead >= n { break }
			start += max(adapted_shift[compared], quick_shift[int(text[lookahead])])
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
