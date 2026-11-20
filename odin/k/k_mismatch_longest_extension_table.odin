package k_mismatch_longest_extension_table

import "core:c"

MAX_N :: 64
MAX_K :: 4
MAX_INPUT :: 67
MAX_OUTPUT :: 320
LEVELS :: 7

pair_less :: proc(a, b, width: int, rank: []int, n: int) -> bool {
	if rank[a] != rank[b] do return rank[a] < rank[b]
	ra := -1
	rb := -1
	if a+width < n do ra = rank[a+width]
	if b+width < n do rb = rank[b+width]
	return ra < rb
}

lce :: proc(a, b, n: int, inverse: []int, sparse: []int, logs: []int) -> int {
	if a >= n || b >= n do return 0
	if a == b do return n-a
	left, right := inverse[a], inverse[b]
	if left > right { left, right = right, left }
	left += 1
	count := right-left+1
	level := logs[count]
	span := 1 << level
	x, y := sparse[level*MAX_N+left], sparse[level*MAX_N+right-span+1]
	if x < y do return x
	return y
}

@(export)
k_mismatch_longest_extension_table :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	nv, kv := input[0], input[1]
	if nv < 1 || nv > MAX_N || kv < 0 || kv > MAX_K do return -1
	n, budget := int(nv), int(kv)
	if length != c.size_t(n+2) do return -1

	text: [MAX_N]int = {}
	suffixes: [MAX_N]int = {}
	rank: [MAX_N]int = {}
	inverse: [MAX_N]int = {}
	lcp: [MAX_N]int = {}
	sparse: [LEVELS*MAX_N]int = {}
	logs: [MAX_N+1]int = {}
	staged: [MAX_OUTPUT]u8 = {}
	for i in 0..<n {
		if input[i+2] < 0 || input[i+2] > 25 do return -1
		text[i] = int(input[i+2])
		suffixes[i] = i
		rank[i] = text[i]
	}

	width := 1
	for width < n {
		for i := 1; i < n; i += 1 {
			key := suffixes[i]
			j := i
			for j > 0 && pair_less(key, suffixes[j-1], width, rank[:], n) {
				suffixes[j] = suffixes[j-1]
				j -= 1
			}
			suffixes[j] = key
		}
		next_rank: [MAX_N]int = {}
		classes := 0
		next_rank[suffixes[0]] = 0
		for i := 1; i < n; i += 1 {
			a, b := suffixes[i-1], suffixes[i]
			a2, b2 := -1, -1
			if a+width < n do a2 = rank[a+width]
			if b+width < n do b2 = rank[b+width]
			if rank[a] != rank[b] || a2 != b2 do classes += 1
			next_rank[b] = classes
		}
		rank = next_rank
		if classes == n-1 || width > n/2 do break
		width *= 2
	}
	for i in 0..<n do inverse[suffixes[i]] = i
	matched := 0
	for start in 0..<n {
		order := inverse[start]
		if order == 0 { matched = 0; continue }
		other := suffixes[order-1]
		for start+matched < n && other+matched < n && text[start+matched] == text[other+matched] do matched += 1
		lcp[order] = matched
		if matched > 0 do matched -= 1
	}
	for i in 0..<n do sparse[i] = lcp[i]
	for level := 1; level < LEVELS; level += 1 {
		span := 1 << level
		half := span/2
		for i := 0; i+span <= n; i += 1 {
			a, b := sparse[(level-1)*MAX_N+i], sparse[(level-1)*MAX_N+i+half]
			if a < b do sparse[level*MAX_N+i] = a else sparse[level*MAX_N+i] = b
		}
	}
	for count := 2; count <= n; count += 1 do logs[count] = logs[count/2]+1

	written := 0
	for p in 0..<n {
		limit := n-p
		extension := lce(0, p, n, inverse[:], sparse[:], logs[:])
		if extension > limit do extension = limit
		staged[written] = u8(extension)
		written += 1
		for k := 1; k <= budget; k += 1 {
			if extension < limit {
				extension += 1+lce(extension+1,p+extension+1,n,inverse[:],sparse[:],logs[:])
				if extension > limit do extension = limit
			}
			staged[written] = u8(extension)
			written += 1
		}
	}
	if written > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(written) do return -2
	for i in 0..<written do output[i] = staged[i]
	return i64(written)
}
