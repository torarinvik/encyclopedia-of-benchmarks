package oi_wiki_maximum_clique_branch_bound

import "core:c"

MAX_VERTICES :: 24
MAX_PARSEABLE_INPUT :: 26

Clique_Search :: struct {
	adjacency: [MAX_VERTICES]u64,
	suffix_best: [MAX_VERTICES]int,
	best: int,
}

bit_count :: proc "contextless" (bits_input: u64) -> int {
	bits := bits_input
	count := 0
	for bits != 0 { bits &= bits-1; count += 1 }
	return count
}

search_clique :: proc "contextless" (search: ^Clique_Search, candidates: u64, chosen: int) -> bool {
	if candidates == 0 {
		if chosen > search.best { search.best = chosen; return true }
		return false
	}
	remaining := candidates
	for remaining != 0 {
		if chosen+bit_count(remaining) <= search.best do return false
		bit := remaining & (~remaining+1)
		vertex := 0
		scan := bit
		for (scan & 1) == 0 { scan >>= 1; vertex += 1 }
		remaining &= ~bit
		if chosen+search.suffix_best[vertex] <= search.best do return false
		if search_clique(search, remaining & search.adjacency[vertex], chosen+1) do return true
	}
	return false
}

@(export)
oi_wiki_maximum_clique_branch_bound :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	n64 := input[0]
	if n64 < 0 || n64 > MAX_VERTICES || length != c.size_t(1+n64) do return -1
	n := int(n64)
	domain := (u64(1)<<n)-1
	search := Clique_Search{}
	for vertex := 0; vertex < n; vertex += 1 {
		row := input[1+vertex]
		if row < 0 || (u64(row)&~domain) != 0 do return -1
		search.adjacency[vertex] = u64(row)
		if search.adjacency[vertex]&(u64(1)<<vertex) != 0 do return -1
	}
	for left := 0; left < n; left += 1 {
		for right := left+1; right < n; right += 1 {
			forward := search.adjacency[left]&(u64(1)<<right) != 0
			reverse := search.adjacency[right]&(u64(1)<<left) != 0
			if forward != reverse do return -1
		}
	}
	for root := n-1; root >= 0; root -= 1 {
		greater := domain&~((u64(1)<<(root+1))-1)
		_ = search_clique(&search, search.adjacency[root]&greater, 1)
		search.suffix_best[root] = search.best
	}
	return i64(search.best)
}
