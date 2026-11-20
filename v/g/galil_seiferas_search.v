module galil_seiferas_search

@[export: 'galil_seiferas_search']
pub fn galil_seiferas_search(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 162 { return -2 }
	nv := unsafe { values[0] }
	mv := unsafe { values[1] }
	if nv < 0 || nv > 128 || mv < 1 || mv > 32 { return -2 }
	n := int(nv)
	m := int(mv)
	if length != usize(2 + n + m) { return -2 }
	for i in 0 .. n + m {
		x := unsafe { values[2 + i] }
		if x < 0 || x > 15 { return -2 }
	}
	if m > n { return 0 }
	pattern_start := 2 + n
	mut s := 0
	mut p1 := 1
	mut q1 := 0
	mut factorized := false
	for {
		for s + p1 + q1 < m && unsafe { values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1] } {
			q1++
		}
		if p1 + q1 >= 4 * p1 {
			mut p2 := q1
			mut q2 := 0
			for {
				for p2 + q2 < 4 * p2 && s + p2 + q2 < m &&
					unsafe { values[pattern_start + s + q2] == values[pattern_start + s + p2 + q2] } {
					q2++
				}
				if p2 + q2 == 4 * p2 {
					for {
						for s + p1 + q1 < m && unsafe { values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1] } {
							q1++
						}
						for p1 + q1 >= 4 * p1 { s += p1; q1 -= p1 }
						if s + p1 + q1 == m { factorized = true; break }
						p1 += q1 / 4 + 1
						q1 = 0
						if p1 >= p2 { break }
					}
					break
				}
				if s + p2 + q2 == m { factorized = true; break }
				if q2 == p1 + q1 { p2 += p1; q2 -= p1 }
				else { p2 += q2 / 4 + 1; q2 = 0 }
			}
			if factorized || s + p1 + q1 == m { break }
		} else {
			if s + p1 + q1 == m { break }
			p1 += q1 / 4 + 1
			q1 = 0
		}
	}
	mut p := 0
	mut q := 0
	mut matches := i64(0)
	for p <= n - m {
		for s + q < m && unsafe { values[pattern_start + s + q] == values[2 + p + s + q] } { q++ }
		if q == m - s {
			mut i := 0
			for i < s && unsafe { values[pattern_start + i] == values[2 + p + i] } { i++ }
			if i == s { matches++ }
		}
		if q == p1 + q1 { p += p1; q -= p1 }
		else { p += q / 4 + 1; q = 0 }
	}
	return matches
}
