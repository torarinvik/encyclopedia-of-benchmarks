module optimal_mismatch

@[export: 'optimal_mismatch']
pub fn optimal_mismatch(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 274 { return -2 }
		raw_n := values[0]
		raw_m := values[1]
		if raw_n < 0 || raw_n > 256 || raw_m < 1 || raw_m > 16 { return -2 }
		n := int(raw_n)
		m := int(raw_m)
		if length != usize(2 + n + m) { return -2 }
		pattern_start := 2 + n
		for i in 0 .. n + m {
			byte := values[2 + i]
			if byte < 0 || byte > 127 { return -2 }
		}
		if m > n { return -1 }

		mut frequency := [128]int{}
		for i in 0 .. n { frequency[int(values[2 + i])]++ }
		mut order := [16]int{}
		for i in 0 .. m { order[i] = i }
		for i in 1 .. m {
			selected := order[i]
			mut cursor := i
			for cursor > 0 {
				previous := order[cursor - 1]
				pf := frequency[int(values[pattern_start + previous])]
				sf := frequency[int(values[pattern_start + selected])]
				if pf < sf || (pf == sf && previous > selected) { break }
				order[cursor] = previous
				cursor--
			}
			order[cursor] = selected
		}

		mut quick_shift := [128]int{init: m + 1}
		for i in 0 .. m { quick_shift[int(values[pattern_start + i])] = m - i }
		mut adapted_shift := [16]int{init: m}
		for rank in 0 .. m {
			mismatch := order[rank]
			for shift in 1 .. m + 1 {
				mut compatible := true
				for prior in 0 .. rank {
					position := order[prior]
					if position >= shift && values[pattern_start + position] != values[pattern_start + position - shift] {
						compatible = false
						break
					}
				}
				if !compatible { continue }
				if mismatch >= shift && values[pattern_start + mismatch - shift] == values[pattern_start + mismatch] { continue }
				adapted_shift[rank] = shift
				break
			}
		}

		mut start := 0
		last_start := n - m
		for start <= last_start {
			mut rank := 0
			for rank < m && values[2 + start + order[rank]] == values[pattern_start + order[rank]] { rank++ }
			if rank == m { return i64(start) }
			if start + m == n { break }
			quick := quick_shift[int(values[2 + start + m])]
			start += if adapted_shift[rank] > quick { adapted_shift[rank] } else { quick }
		}
		return -1
	}
}
