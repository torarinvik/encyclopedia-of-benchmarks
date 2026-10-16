package palindromic_partitioning

import "core:c"

@(export)
palindromic_partitioning :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n < 2 || n > 65 || v[0] < 1 || v[0] > 64 || n != c.size_t(v[0] + 1) do return -1
	m := int(v[0]); p: [64][64]bool; cuts: [64]i64
	for ending := 0; ending < m; ending += 1 {
		x := v[ending + 1]; if x < 0 || x > 127 do return -1
		for start := 0; start <= ending; start += 1 { p[start][ending] = v[start + 1] == x && (ending - start < 2 || p[start + 1][ending - 1]) }
	}
	for ending := 0; ending < m; ending += 1 {
		if p[0][ending] { cuts[ending] = 0 } else {
			cuts[ending] = 64
			for start := 1; start <= ending; start += 1 { if p[start][ending] && cuts[start - 1] + 1 < cuts[ending] { cuts[ending] = cuts[start - 1] + 1 } }
		}
	}
	return cuts[m - 1]
}
