package non_shared_edges

import "core:c"

MAX_LEAVES :: 8
MAX_EDGES :: 13
MAX_INPUT :: 27

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

bit_count :: proc(value: u64, n: int) -> int {
	count := 0
	for bit := 0; bit < n; bit += 1 { count += int((value >> u64(bit)) & 1) }
	return count
}

valid_tree :: proc(input: [^]i64, offset, n, edges: int) -> bool {
	masks: [MAX_EDGES]u64
	internal: [MAX_EDGES]u64
	internal_count := 0
	universe := (u64(1) << u64(n)) - 1
	for edge := 0; edge < edges; edge += 1 {
		raw := input[offset + edge]
		if raw <= 0 || u64(raw) >= universe || (raw & 1) != 0 do return false
		masks[edge] = u64(raw)
		for earlier := 0; earlier < edge; earlier += 1 { if masks[earlier] == masks[edge] do return false }
		size := bit_count(masks[edge], n)
		if size == 1 || size == n - 1 {
			if size == n - 1 && masks[edge] != (universe ^ 1) do return false
		} else if size >= 2 && size <= n - 2 {
			internal[internal_count] = masks[edge]
			internal_count += 1
		} else {
			return false
		}
	}
	if internal_count != n - 3 do return false
	for leaf := 1; leaf < n; leaf += 1 {
		pendant := u64(1) << u64(leaf)
		found := 0
		for edge := 0; edge < edges; edge += 1 { if masks[edge] == pendant do found += 1 }
		if found != 1 do return false
	}
	root_pendant := 0
	for edge := 0; edge < edges; edge += 1 { if masks[edge] == (universe ^ 1) do root_pendant += 1 }
	if root_pendant != 1 do return false
	for i := 0; i < internal_count; i += 1 {
		for j := i + 1; j < internal_count; j += 1 {
			intersection := internal[i] & internal[j]
			if intersection != 0 && intersection != internal[i] && intersection != internal[j] do return false
		}
	}
	return true
}

@(export)
non_shared_edges :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 7 || length > MAX_INPUT do return -1
	leaf_value := input[0]
	if leaf_value < 3 || leaf_value > MAX_LEAVES do return -1
	leaves := int(leaf_value)
	edges := 2 * leaves - 3
	if length != c.size_t(1 + 2*edges) do return -1
	second := 1 + edges
	if !valid_tree(input, 1, leaves, edges) || !valid_tree(input, second, leaves, edges) do return -1
	shared: i64 = 0
	for left := 0; left < edges; left += 1 {
		for right := 0; right < edges; right += 1 {
			if input[1+left] == input[second+right] { shared += 1; break }
		}
	}
	if output == nil || capacity < 8 do return -2
	staged: [8]u8
	store_i64_le(&staged[0], i64(edges) - shared)
	for byte := 0; byte < 8; byte += 1 { output[byte] = staged[byte] }
	return 8
}
