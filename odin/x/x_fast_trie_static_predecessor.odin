package x_fast_trie_static_predecessor

import "core:c"

MAX_KEYS :: 24
MAX_QUERIES :: 24
UNIVERSE_BITS :: 16
LEVELS :: 17
MAX_PARSEABLE :: 51

prefix_of :: proc(key: i64, depth: int) -> i64 {
	if depth == 0 do return 0
	return key >> (UNIVERSE_BITS - depth)
}

find_prefix :: proc(prefixes: [^]i64, counts: [^]int, depth: int, wanted: i64) -> int {
	low, high := 0, counts[depth]
	row := depth * MAX_KEYS
	for low < high {
		middle := low + (high - low) / 2
		if prefixes[row + middle] < wanted do low = middle + 1 else high = middle
	}
	if low < counts[depth] && prefixes[row + low] == wanted do return low
	return -1
}

predecessor :: proc(prefixes: [^]i64, maxima: [^]i64, counts: [^]int, query: i64) -> i64 {
	low, high := 0, LEVELS
	for high - low > 1 {
		middle := low + (high - low) / 2
		if find_prefix(prefixes, counts, middle, prefix_of(query, middle)) >= 0 do low = middle else high = middle
	}
	if low == UNIVERSE_BITS do return query
	for depth := low + 1; depth > 0; depth -= 1 {
		query_prefix := query >> (UNIVERSE_BITS - depth)
		if query_prefix & 1 != 0 {
			position := find_prefix(prefixes, counts, depth, query_prefix - 1)
			if position >= 0 do return maxima[depth * MAX_KEYS + position]
		}
	}
	return -1
}

@(export)
x_fast_trie_static_predecessor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE do return -1
	if input[0] < 0 || input[0] > MAX_KEYS || input[1] < 0 || input[1] > MAX_QUERIES do return -1
	n, q := int(input[0]), int(input[1])
	if length != c.size_t(2 + n + q) do return -1
	var keys: [MAX_KEYS]i64
	var queries: [MAX_QUERIES]i64
	for i := 0; i < n; i += 1 {
		keys[i] = input[2 + i]
		if keys[i] < 0 || keys[i] > 65535 do return -1
	}
	for i := 1; i < n; i += 1 {
		key := keys[i]
		at := i
		for at > 0 && key < keys[at - 1] { keys[at] = keys[at - 1]; at -= 1 }
		keys[at] = key
	}
	for i := 1; i < n; i += 1 do if keys[i] == keys[i - 1] do return -1
	for i := 0; i < q; i += 1 {
		queries[i] = input[2 + n + i]
		if queries[i] < 0 || queries[i] > 65535 do return -1
	}
	if n == 0 || q == 0 do return 0

	var prefixes: [LEVELS * MAX_KEYS]i64
	var maxima: [LEVELS * MAX_KEYS]i64
	var counts: [LEVELS]int
	for depth := 0; depth < LEVELS; depth += 1 {
		row := depth * MAX_KEYS
		for i := 0; i < n; i += 1 {
			value := prefix_of(keys[i], depth)
			count := counts[depth]
			if count == 0 || prefixes[row + count - 1] != value {
				prefixes[row + count] = value
				maxima[row + count] = keys[i]
				counts[depth] += 1
			} else maxima[row + count - 1] = keys[i]
		}
	}
	checksum: i64 = 0
	for i := 0; i < q; i += 1 do checksum += i64(i + 1) * (predecessor(&prefixes[0], &maxima[0], &counts[0], queries[i]) + 1)
	return checksum
}
