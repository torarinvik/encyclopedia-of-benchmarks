package simon_string_search

import "core:c"

@(export)
simon_string_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 274 do return -2
	if values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16 do return -2
	n := c.size_t(values[0])
	m := c.size_t(values[1])
	if length != 2 + n + m do return -2
	for i := c.size_t(0); i < n + m; i += 1 {
		if values[2 + i] < 0 || values[2 + i] > 15 do return -2
	}
	p := 2 + n
	head: [16]int
	edge_target: [16]int
	edge_next: [16]int
	for i := 0; i < 16; i += 1 { head[i] = -1 }
	edge_count := 0
	ell := -1
	for i := c.size_t(1); i < m; i += 1 {
		k := ell
		cell := -1
		if k >= 0 { cell = head[k] }
		ell = -1
		if values[p + i] == values[p + c.size_t(k + 1)] {
			ell = k + 1
		} else {
			edge_target[edge_count] = k + 1
			edge_next[edge_count] = head[int(i - 1)]
			head[int(i - 1)] = edge_count
			edge_count += 1
		}
		for cell >= 0 {
			q := edge_target[cell]
			if values[p + i] == values[p + c.size_t(q)] {
				ell = q
			} else {
				edge_target[edge_count] = q
				edge_next[edge_count] = head[int(i - 1)]
				head[int(i - 1)] = edge_count
				edge_count += 1
			}
			cell = edge_next[cell]
		}
	}
	state := -1
	matches: i64 = 0
	for j := c.size_t(0); j < n; j += 1 {
		symbol := values[2 + j]
		if state < int(m) - 1 && values[p + c.size_t(state + 1)] == symbol {
			state += 1
		} else if state >= 0 {
			edge := head[state]
			state = -1
			for edge >= 0 {
				q := edge_target[edge]
				if values[p + c.size_t(q)] == symbol { state = q; break }
				edge = edge_next[edge]
			}
		}
		if state >= int(m) - 1 { matches += 1; state = ell }
	}
	return matches
}
