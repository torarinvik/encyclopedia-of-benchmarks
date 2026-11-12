package hunt_szymanski_lcs

import "core:c"

// Return the LCS length using matching positions and a minimum-tail frontier.
@(export)
hunt_szymanski_lcs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 131 do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value < 0 || n_value > 64 || m_value < 0 || m_value > 64 do return -1
	if length != c.size_t(2 + n_value + m_value) do return -1
	n := int(n_value)
	m := int(m_value)
	for i := 0; i < n + m; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 127 do return -1
	}

	right_positions: [8192]i32 = {}
	position_count: [128]i32 = {}
	tails: [64]i32 = {}
	for j := 0; j < m; j += 1 {
		symbol := int(input[2 + n + j])
		count := int(position_count[symbol])
		right_positions[symbol * 64 + count] = i32(j)
		position_count[symbol] = i32(count + 1)
	}

	tail_count := 0
	for i := 0; i < n; i += 1 {
		symbol := int(input[2 + i])
		count := int(position_count[symbol])
		for count > 0 {
			count -= 1
			position := right_positions[symbol * 64 + count]
			low := 0
			high := tail_count
			for low < high {
				middle := low + (high - low) / 2
				if tails[middle] >= position do high = middle
				else do low = middle + 1
			}
			if low == tail_count {
				tails[tail_count] = position
				tail_count += 1
			} else {
				tails[low] = position
			}
		}
	}
	return i64(tail_count)
}
