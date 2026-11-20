package optimal_mismatch

import "core:c"

@(export)
optimal_mismatch :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 274 do return -2
	if values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16 do return -2
	n := c.size_t(values[0])
	m := c.size_t(values[1])
	if length != 2 + n + m do return -2
	pattern_start := 2 + n
	for i := c.size_t(0); i < n + m; i += 1 {
		if values[2 + i] < 0 || values[2 + i] > 127 do return -2
	}
	if m > n do return -1

	frequency: [128]c.size_t
	for byte := c.size_t(0); byte < 128; byte += 1 { frequency[byte] = 0 }
	for i := c.size_t(0); i < n; i += 1 {
		frequency[int(values[2 + i])] += 1
	}
	order: [16]c.size_t
	for i := c.size_t(0); i < m; i += 1 { order[i] = i }
	for i := c.size_t(1); i < m; i += 1 {
		selected := order[i]
		cursor := i
		for cursor > 0 {
			previous := order[cursor - 1]
			pf := frequency[int(values[pattern_start + previous])]
			sf := frequency[int(values[pattern_start + selected])]
			if pf < sf || (pf == sf && previous > selected) do break
			order[cursor] = previous
			cursor -= 1
		}
		order[cursor] = selected
	}

	quick_shift: [128]c.size_t
	for byte := c.size_t(0); byte < 128; byte += 1 { quick_shift[byte] = m + 1 }
	for i := c.size_t(0); i < m; i += 1 {
		quick_shift[int(values[pattern_start + i])] = m - i
	}
	adapted_shift: [16]c.size_t
	for rank := c.size_t(0); rank < m; rank += 1 {
		adapted_shift[rank] = m
		mismatch := order[rank]
		for shift := c.size_t(1); shift <= m; shift += 1 {
			compatible := true
			for prior := c.size_t(0); prior < rank; prior += 1 {
				position := order[prior]
				if position >= shift && values[pattern_start + position] != values[pattern_start + position - shift] {
					compatible = false
					break
				}
			}
			if !compatible do continue
			if mismatch >= shift && values[pattern_start + mismatch - shift] == values[pattern_start + mismatch] do continue
			adapted_shift[rank] = shift
			break
		}
	}

	start := c.size_t(0)
	last_start := n - m
	for start <= last_start {
		rank := c.size_t(0)
		for rank < m && values[2 + start + order[rank]] == values[pattern_start + order[rank]] {
			rank += 1
		}
		if rank == m do return i64(start)
		if start + m == n do break
		quick := quick_shift[int(values[2 + start + m])]
		if adapted_shift[rank] > quick { start += adapted_shift[rank] } else { start += quick }
	}
	return -1
}
