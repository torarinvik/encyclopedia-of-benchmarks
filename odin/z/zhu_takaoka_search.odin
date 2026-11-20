package zhu_takaoka_search

import "core:c"

@(export)
zhu_takaoka_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 274 do return -2
	if values[0] < 0 || values[0] > 256 || values[1] < 2 || values[1] > 16 do return -2
	n, m := int(values[0]), int(values[1])
	if length != c.size_t(2 + n + m) do return -2
	for i := 0; i < n + m; i += 1 {
		if values[2+i] < 0 || values[2+i] >= 16 do return -2
	}
	if m > n do return -1

	p := 2 + n
	var pair_shift: [256]int = {}
	for i := 0; i < 256; i += 1 do pair_shift[i] = m
	for a := 0; a < 16; a += 1 do pair_shift[a*16+int(values[p])] = m - 1
	for i := 1; i < m - 1; i += 1 {
		pair_shift[int(values[p+i-1])*16+int(values[p+i])] = m - 1 - i
	}

	var good_suffix: [16]int = {}
	for mismatch := 0; mismatch < m; mismatch += 1 {
		good_suffix[mismatch] = m
		for shift := 1; shift <= m; shift += 1 {
			first_known := mismatch + 1
			if shift > first_known do first_known = shift
			position := first_known
			for position < m && values[p+position] == values[p+position-shift] { position += 1 }
			if position < m do continue
			if mismatch+1 < m && shift <= mismatch && values[p+mismatch-shift] == values[p+mismatch] do continue
			good_suffix[mismatch] = shift
			break
		}
	}

	start := 0
	for start <= n-m {
		mismatch := m
		for mismatch > 0 && values[p+mismatch-1] == values[2+start+mismatch-1] { mismatch -= 1 }
		if mismatch == 0 do return i64(start)
		mismatch -= 1
		first, second := int(values[2+start+m-2]), int(values[2+start+m-1])
		shift := good_suffix[mismatch]
		if pair_shift[first*16+second] > shift do shift = pair_shift[first*16+second]
		start += shift
	}
	return -1
}
