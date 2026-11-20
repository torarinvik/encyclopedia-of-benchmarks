module zhu_takaoka_search

@[export: 'zhu_takaoka_search']
pub fn zhu_takaoka_search(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 274 { return -2 }
		if values[0] < 0 || values[0] > 256 || values[1] < 2 || values[1] > 16 { return -2 }
		n := int(values[0])
		m := int(values[1])
		if length != usize(2 + n + m) { return -2 }
		for i in 0 .. n + m {
			if values[2 + i] < 0 || values[2 + i] >= 16 { return -2 }
		}
		if m > n { return -1 }

		p := 2 + n
		mut pair_shift := [256]int{}
		for i in 0 .. 256 { pair_shift[i] = m }
		for first in 0 .. 16 { pair_shift[first * 16 + int(values[p])] = m - 1 }
		for i in 1 .. m - 1 {
			pair_shift[int(values[p + i - 1]) * 16 + int(values[p + i])] = m - 1 - i
		}

		mut good_suffix := [16]int{}
		for mismatch in 0 .. m {
			good_suffix[mismatch] = m
			for shift in 1 .. m + 1 {
				first_known := if mismatch + 1 > shift { mismatch + 1 } else { shift }
				mut position := first_known
				for position < m && values[p + position] == values[p + position - shift] { position++ }
				if position < m { continue }
				if mismatch + 1 < m && shift <= mismatch && values[p + mismatch - shift] == values[p + mismatch] { continue }
				good_suffix[mismatch] = shift
				break
			}
		}

		mut start := 0
		for start <= n - m {
			mut mismatch := m
			for mismatch > 0 && values[p + mismatch - 1] == values[2 + start + mismatch - 1] { mismatch-- }
			if mismatch == 0 { return i64(start) }
			mismatch--
			first := int(values[2 + start + m - 2])
			second := int(values[2 + start + m - 1])
			shift := good_suffix[mismatch]
			if pair_shift[first * 16 + second] > shift { shift = pair_shift[first * 16 + second] }
			start += shift
		}
		return -1
	}
}
