package minimal_dominating_sets_interval

import "core:c"

intervals_intersect :: proc(s, e: [^]i64, a, b: int) -> bool {
	return s[a] <= e[b] && s[b] <= e[a]
}

@(export)
minimal_dominating_sets_interval :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 25 do return -1
	n0 := input[0]
	if n0 < 1 || n0 > 12 || length != c.size_t(1 + 2*n0) do return -1
	n := int(n0); s: [12]i64; e: [12]i64
	min_end, max_start := i64(0), i64(0)
	for i := 0; i < n; i += 1 {
		s[i] = input[1+2*i]; e[i] = input[2+2*i]
		if s[i] < -100 || s[i] > 100 || e[i] < -100 || e[i] > 100 || s[i] >= e[i] do return -1
		if i > 0 && s[i-1] >= s[i] do return -1
		if i == 0 || e[i] < min_end do min_end = e[i]
		if i == 0 || s[i] > max_start do max_start = s[i]
		for j := 0; j < i; j += 1 { if s[i] == s[j] || s[i] == e[j] || e[i] == s[j] || e[i] == e[j] do return -1 }
	}
	if output == nil || output_capacity < 8 do return -2
	has_next: [12]bool = 0; ncs: [12]i64 = 0; nce: [12]i64 = 0; p_single: [12]i64
	for i := 0; i < n; i += 1 {
		p_single[i] = 0x7fffffffffffffff
		for z := 0; z < n; z += 1 {
			if intervals_intersect(&s[0], &e[0], i, z) && e[z] < p_single[i] do p_single[i] = e[z]
			if s[z] > e[i] {
				if !has_next[i] || s[z] < ncs[i] do ncs[i] = s[z]
				if !has_next[i] || e[z] < nce[i] do nce[i] = e[z]
				has_next[i] = true
			}
		}
	}
	valid: [12][12]bool = 0; p_pair: [12][12]i64 = 0
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 {
		p_pair[i][j] = 0x7fffffffffffffff
		for z := 0; z < n; z += 1 { if intervals_intersect(&s[0],&e[0],j,z) && !intervals_intersect(&s[0],&e[0],i,z) && e[z] < p_pair[i][j] do p_pair[i][j]=e[z] }
		valid[i][j] = has_next[i] && p_single[i] < s[j] && s[j] <= nce[i] && e[j] >= ncs[i]
	} }
	ways: [12][12]i64 = 0
	for j := 1; j < n; j += 1 { for i := 0; i < j; i += 1 {
		if !valid[i][j] do continue
		if s[i] <= min_end do ways[i][j] += 1
		for k := j+1; k < n; k += 1 { if valid[j][k] && p_pair[i][j] < s[k] && s[k] <= nce[j] do ways[j][k] += ways[i][j] }
	} }
	count := i64(0)
	for i := 0; i < n; i += 1 { if s[i] <= min_end && e[i] >= max_start do count += 1 }
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if e[j] >= max_start do count += ways[i][j] } }
	bits := u64(count)
	for b := 0; b < 8; b += 1 { output[b] = u8((bits >> (8*b)) & 0xff) }
	return 8
}
