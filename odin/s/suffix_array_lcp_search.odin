package suffix_array_lcp_search

import "core:c"

MAX_N :: 32
MAX_M :: 16
MAX_INPUT :: 50
MAX_OUTPUT :: 264

put_i64 :: proc(out: [^]u8, offset: int, value: int) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 {
		out[offset+b] = u8((bits >> (b*8)) & 255)
	}
}

suffix_cmp :: proc(text: [MAX_N]i64, a, b, n: int) -> int {
	k := 0
	for a+k < n && b+k < n {
		if text[a+k] < text[b+k] do return -1
		if text[a+k] > text[b+k] do return 1
		k += 1
	}
	if a+k == n && b+k == n do return 0
	if a+k == n do return -1
	return 1
}

pattern_cmp :: proc(text: [MAX_N]i64, start, n: int,
		pattern: [MAX_M]i64, m, offset: int, prefix_equal: bool,
		matched_out: ^int) -> int {
	matched_out^ = offset
	for matched_out^ < m && start+matched_out^ < n && text[start+matched_out^] == pattern[matched_out^] {
		matched_out^ += 1
	}
	if matched_out^ == m {
		if prefix_equal || start+matched_out^ == n do return 0
		return 1
	}
	if start+matched_out^ == n do return -1
	if text[start+matched_out^] < pattern[matched_out^] do return -1
	return 1
}

build_intervals :: proc(n: int, lcp: [MAX_N]int,
		left_q, right_q: ^[MAX_N*MAX_N]int) {
	lo_stack: [2*MAX_N]int
	hi_stack: [2*MAX_N]int
	top := 1
	lo_stack[0] = 0
	hi_stack[0] = n-1
	for top > 0 {
		top -= 1
		lo, hi := lo_stack[top], hi_stack[top]
		if hi-lo < 2 do continue
		mid := (lo+hi+1)/2
		q := n+1
		for k := lo; k < mid; k += 1 { if lcp[k] < q do q = lcp[k] }
		left_q^[lo*MAX_N+hi] = q
		q = n+1
		for k := mid; k < hi; k += 1 { if lcp[k] < q do q = lcp[k] }
		right_q^[lo*MAX_N+hi] = q
		if hi-mid >= 2 { lo_stack[top] = mid; hi_stack[top] = hi; top += 1 }
		if mid-lo >= 2 { lo_stack[top] = lo; hi_stack[top] = mid; top += 1 }
	}
}

bound :: proc(text: [MAX_N]i64, n: int, pattern: [MAX_M]i64, m: int,
		suffix: [MAX_N]int, left_q, right_q: [MAX_N*MAX_N]int,
		prefix_equal: bool) -> int {
	l, r := 0, 0
	first := pattern_cmp(text, suffix[0], n, pattern, m, 0, prefix_equal, &l)
	if first > 0 || (!prefix_equal && first == 0) do return 0
	last := pattern_cmp(text, suffix[n-1], n, pattern, m, 0, prefix_equal, &r)
	if last < 0 || (prefix_equal && last == 0) do return n
	lo, hi := 0, n-1
	for hi-lo > 1 {
		mid := (lo+hi+1)/2
		cmp, matched := 0, 0
		if l == r {
			cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched)
			if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
		} else if l > r {
			q := left_q[lo*MAX_N+hi]
			if l < q { lo = mid } else if l > q { hi = mid; r = q } else {
				cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched)
				if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
			}
		} else {
			q := right_q[lo*MAX_N+hi]
			if r < q { hi = mid } else if r > q { lo = mid; l = q } else {
				cmp = pattern_cmp(text, suffix[mid], n, pattern, m, r, prefix_equal, &matched)
				if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched } else { lo = mid; l = matched }
			}
		}
	}
	return hi
}

@(export)
suffix_array_lcp_search :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > MAX_INPUT do return -1
	if values[0] < 1 || values[0] > MAX_N do return -1
	n := int(values[0])
	if int(length) < n+2 do return -1
	if values[n+1] < 1 || values[n+1] > MAX_M do return -1
	m := int(values[n+1])
	if int(length) != n+m+2 do return -1
	text: [MAX_N]i64
	pattern: [MAX_M]i64
	suffix: [MAX_N]int
	lcp: [MAX_N]int
	left_q: [MAX_N*MAX_N]int
	right_q: [MAX_N*MAX_N]int
	for i := 0; i < n; i += 1 {
		text[i] = values[1+i]
		if text[i] < 0 || text[i] > 127 do return -1
		suffix[i] = i
	}
	for i := 0; i < m; i += 1 {
		pattern[i] = values[n+2+i]
		if pattern[i] < 0 || pattern[i] > 127 do return -1
	}
	for i := 1; i < n; i += 1 {
		key := suffix[i]
		j := i
		for j > 0 && suffix_cmp(text, key, suffix[j-1], n) < 0 { suffix[j] = suffix[j-1]; j -= 1 }
		suffix[j] = key
	}
	for i := 0; i+1 < n; i += 1 {
		a, b := suffix[i], suffix[i+1]
		k := 0
		for a+k < n && b+k < n && text[a+k] == text[b+k] { k += 1 }
		lcp[i] = k
	}
	build_intervals(n, lcp, &left_q, &right_q)
	first := bound(text, n, pattern, m, suffix, left_q, right_q, false)
	last := bound(text, n, pattern, m, suffix, left_q, right_q, true)
	count := last-first
	bytes := 8*(count+1)
	if output == nil || int(output_capacity) < bytes do return -2
	staged: [MAX_OUTPUT]u8
	put_i64(&staged[0], 0, count)
	for i := 0; i < count; i += 1 { put_i64(&staged[0], 8*(i+1), suffix[first+i]) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
