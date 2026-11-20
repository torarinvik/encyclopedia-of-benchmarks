package bidirectional_fm_index

import "core:c"

Index :: struct {
	cumulative: [5]int,
	bwt: [65]i64,
}

suffix_less :: proc(s: [^]i64, total: int, a0, b0: int) -> bool {
	a, b := a0, b0
	for a < total && b < total {
		if s[a] != s[b] do return s[a] < s[b]
		a += 1
		b += 1
	}
	return a == total && b != total
}

build_index :: proc(s: [^]i64, total: int) -> Index {
	result: Index
	suffixes: [65]int
	frequency: [5]int
	for i := 0; i < total; i += 1 { suffixes[i] = i }
	for i := 1; i < total; i += 1 {
		key := suffixes[i]
		j := i
		for j > 0 && suffix_less(s, total, key, suffixes[j-1]) { suffixes[j] = suffixes[j-1]; j -= 1 }
		suffixes[j] = key
	}
	for i := 0; i < total; i += 1 {
		result.bwt[i] = s[(suffixes[i]+total-1)%total]
		frequency[int(result.bwt[i])] += 1
	}
	seen := 0
	for symbol := 0; symbol < 5; symbol += 1 { result.cumulative[symbol] = seen; seen += frequency[symbol] }
	return result
}

rank_before :: proc(index: Index, end_at, symbol: int) -> int {
	count := 0
	for i := 0; i < end_at; i += 1 { if int(index.bwt[i]) == symbol do count += 1 }
	return count
}

@(export)
bidirectional_fm_index :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 195 do return -1
	n0, q0 := input[0], input[1]
	if n0 < 0 || n0 > 64 || q0 < 0 || q0 > 64 do return -1
	n, q := int(n0), int(q0)
	if length != c.size_t(2 + n + 2*q) do return -1
	forward_text: [65]i64
	reverse_text: [65]i64
	for i := 0; i < n; i += 1 {
		symbol := input[2+i]
		if symbol < 1 || symbol > 4 do return -1
		forward_text[i] = symbol
		reverse_text[n-1-i] = symbol
	}
	forward_text[n] = 0
	reverse_text[n] = 0
	for op := 0; op < q; op += 1 {
		side, symbol := input[2+n+2*op], input[3+n+2*op]
		if (side != 0 && side != 1) || symbol < 1 || symbol > 4 do return -1
	}
	total := n + 1
	forward := build_index(&forward_text[0], total)
	reverse := build_index(&reverse_text[0], total)
	fl, fr, rl, rr := 0, total, 0, total
	checksum: i64 = 0
	for op := 0; op < q; op += 1 {
		side, symbol := int(input[2+n+2*op]), int(input[3+n+2*op])
		old_fl, old_fr, old_rl, old_rr := fl, fr, rl, rr
		if side == 0 {
			fl = forward.cumulative[symbol] + rank_before(forward, old_fl, symbol)
			fr = forward.cumulative[symbol] + rank_before(forward, old_fr, symbol)
			start := old_rl
			for smaller := 0; smaller < symbol; smaller += 1 { start += rank_before(forward, old_fr, smaller) - rank_before(forward, old_fl, smaller) }
			count := rank_before(forward, old_fr, symbol) - rank_before(forward, old_fl, symbol)
			rl, rr = start, start+count
		} else {
			rl = reverse.cumulative[symbol] + rank_before(reverse, old_rl, symbol)
			rr = reverse.cumulative[symbol] + rank_before(reverse, old_rr, symbol)
			start := old_fl
			for smaller := 0; smaller < symbol; smaller += 1 { start += rank_before(reverse, old_rr, smaller) - rank_before(reverse, old_rl, smaller) }
			count := rank_before(reverse, old_rr, symbol) - rank_before(reverse, old_rl, symbol)
			fl, fr = start, start+count
		}
		checksum += i64(op+1) * i64(fr-fl)
	}
	return checksum
}
