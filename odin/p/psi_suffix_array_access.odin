package psi_suffix_array_access

import "core:c"

put_u64 :: proc(out: [^]u8, word: int, value: u64) {
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((value >> u64(8*b)) & 255) }
}

psi_suffix_array_access :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 67 do return -1
	n0, query0, stride0 := input[0], input[1], input[2]
	if n0 < 1 || n0 > 32 || query0 < 0 || query0 >= n0 || stride0 < 1 || stride0 > n0 || length != c.size_t(3+2*n0) do return -1
	n, query, stride := int(n0), int(query0), int(stride0)
	destinations: [32]bool
	visited: [32]bool
	for i := 0; i < n; i += 1 { destinations[i] = false; visited[i] = false }
	for i := 0; i < n; i += 1 {
		next, sample := input[3+i], input[3+n+i]
		if next < 0 || next >= n0 || destinations[int(next)] || sample < 0 || sample > n0 do return -1
		destinations[int(next)] = true
	}
	anchor := -1
	for i := 0; i < n; i += 1 { if input[3+n+i] != 0 { anchor = i; break } }
	if anchor < 0 do return -1
	anchor_value := input[3+n+anchor]
	if (anchor_value - 1) % stride0 != 0 do return -1
	full_sa: [32]u64
	for i := 0; i < n; i += 1 { full_sa[i] = 0 }
	rank, value := anchor, anchor_value
	for step := 0; step < n; step += 1 {
		if visited[rank] do return -1
		visited[rank] = true; full_sa[rank] = u64(value)
		rank = int(input[3+rank])
		if value == n0 { value = 1 } else { value += 1 }
	}
	if rank != anchor || value != anchor_value do return -1
	for i := 0; i < n; i += 1 {
		expected := i64(0)
		if (full_sa[i] - 1) % u64(stride) == 0 { expected = i64(full_sa[i]) }
		if input[3+n+i] != expected do return -1
	}
	rank, hops := query, 0
	for input[3+n+rank] == 0 {
		rank = int(input[3+rank]); hops += 1
		if hops >= stride do return -1
	}
	position0 := input[3+n+rank] - 1 - i64(hops)
	position0 %= n0
	if position0 < 0 { position0 += n0 }
	if output == nil || capacity < 16 do return -2
	put_u64(output, 0, u64(position0+1)); put_u64(output, 1, u64(hops))
	return 16
}
