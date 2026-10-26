package fm_index_count

import "core:c"

suffix_less :: proc(s: [^]i64, n: int, a0, b0: int) -> bool {
	a, b := a0, b0
	for a < n && b < n {
		if s[a] != s[b] do return s[a] < s[b]
		a += 1; b += 1
	}
	return a == n && b != n
}

@(export)
fm_index_count :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 42 do return -1
	n0 := input[0]
	if n0 < 1 || n0 > 32 || length < c.size_t(n0 + 3) do return -1
	n := int(n0); m_at := n + 1; m0 := input[m_at]
	if m0 < 1 || m0 > 8 || length != c.size_t(n + m0 + 2) do return -1
	m := int(m0); total := n + 1
	s: [33]i64
	pattern: [8]i64
	for i := 0; i < n; i += 1 { if input[1+i] < 1 || input[1+i] > 4 do return -1; s[i] = input[1+i] }
	for i := 0; i < m; i += 1 { if input[m_at+1+i] < 1 || input[m_at+1+i] > 4 do return -1; pattern[i] = input[m_at+1+i] }
	s[n] = 0
	if output == nil || output_capacity < 8 do return -2
	sa: [33]int
	for i := 0; i < total; i += 1 { sa[i] = i }
	for i := 1; i < total; i += 1 {
		key := sa[i]; j := i
		for j > 0 && suffix_less(&s[0], total, key, sa[j-1]) { sa[j] = sa[j-1]; j -= 1 }
		sa[j] = key
	}
	bwt: [33]int; freq: [5]int = 0
	for i := 0; i < total; i += 1 { bwt[i] = s[(sa[i]+total-1)%total]; freq[bwt[i]] += 1 }
	cumulative: [5]int; sum := 0
	for x := 0; x < 5; x += 1 { cumulative[x] = sum; sum += freq[x] }
	left, right := 0, total
	for k := 0; k < m; k += 1 {
		symbol := int(pattern[m-1-k]); rl, rr := 0, 0
		for i := 0; i < left; i += 1 { if bwt[i] == symbol do rl += 1 }
		for i := 0; i < right; i += 1 { if bwt[i] == symbol do rr += 1 }
		left = cumulative[symbol] + rl; right = cumulative[symbol] + rr
		if left == right do break
	}
	count := u64(right-left)
	for i := 0; i < 8; i += 1 { output[i] = u8((count >> (8*i)) & 0xff) }
	return 8
}
