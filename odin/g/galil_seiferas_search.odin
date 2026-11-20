package galil_seiferas_search

import "core:c"

@(export)
galil_seiferas_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 162 do return -2
	if values[0] < 0 || values[0] > 128 || values[1] < 1 || values[1] > 32 do return -2
	n, m := int(values[0]), int(values[1])
	if length != c.size_t(2 + n + m) do return -2
	for i := 0; i < n + m; i += 1 {
		if values[2 + i] < 0 || values[2 + i] > 15 do return -2
	}
	if m > n do return 0
	pattern_start := 2 + n
	s, p1, q1 := 0, 1, 0
	factorized := false
	for {
		for s + p1 + q1 < m && values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1] {
			q1 += 1
		}
		if p1 + q1 >= 4 * p1 {
			p2, q2 := q1, 0
			for {
				for p2 + q2 < 4 * p2 && s + p2 + q2 < m &&
					values[pattern_start + s + q2] == values[pattern_start + s + p2 + q2] {
					q2 += 1
				}
				if p2 + q2 == 4 * p2 {
					for {
						for s + p1 + q1 < m && values[pattern_start + s + q1] == values[pattern_start + s + p1 + q1] {
							q1 += 1
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
			if factorized { break }
			if s + p1 + q1 == m { break }
		} else {
			if s + p1 + q1 == m { break }
			p1 += q1 / 4 + 1
			q1 = 0
		}
	}
	p, q := 0, 0
	matches: i64 = 0
	for p <= n - m {
		for s + q < m && values[pattern_start + s + q] == values[2 + p + s + q] { q += 1 }
		if q == m - s {
			i := 0
			for i < s && values[pattern_start + i] == values[2 + p + i] { i += 1 }
			if i == s { matches += 1 }
		}
		if q == p1 + q1 { p += p1; q -= p1 }
		else { p += q / 4 + 1; q = 0 }
	}
	return matches
}
