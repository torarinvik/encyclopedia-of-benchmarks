module simon_string_search

@[export: 'simon_string_search']
pub fn simon_string_search(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 274 { return -2 }
	nv := unsafe { values[0] }
	mv := unsafe { values[1] }
	if nv < 0 || nv > 256 || mv < 1 || mv > 16 { return -2 }
	n := int(nv)
	m := int(mv)
	if length != usize(2 + n + m) { return -2 }
	for i in 0 .. n + m {
		if unsafe { values[2 + i] } < 0 || unsafe { values[2 + i] } > 15 { return -2 }
	}
	p := 2 + n
	mut head := [16]int{init: -1}
	mut edge_target := [16]int{}
	mut edge_next := [16]int{}
	mut edge_count := 0
	mut ell := -1
	for i in 1 .. m {
		k := ell
		mut cell := if k < 0 { -1 } else { head[k] }
		ell = -1
		if unsafe { values[p + i] == values[p + k + 1] } {
			ell = k + 1
		} else {
			edge_target[edge_count] = k + 1
			edge_next[edge_count] = head[i - 1]
			head[i - 1] = edge_count
			edge_count++
		}
		for cell >= 0 {
			q := edge_target[cell]
			if unsafe { values[p + i] == values[p + q] } {
				ell = q
			} else {
				edge_target[edge_count] = q
				edge_next[edge_count] = head[i - 1]
				head[i - 1] = edge_count
				edge_count++
			}
			cell = edge_next[cell]
		}
	}
	mut state := -1
	mut matches := i64(0)
	for j in 0 .. n {
		symbol := unsafe { values[2 + j] }
		if state < m - 1 && unsafe { values[p + state + 1] == symbol } {
			state++
		} else if state >= 0 {
			mut edge := head[state]
			state = -1
			for edge >= 0 {
				q := edge_target[edge]
				if unsafe { values[p + q] == symbol } { state = q; break }
				edge = edge_next[edge]
			}
		}
		if state >= m - 1 { matches++; state = ell }
	}
	return matches
}
