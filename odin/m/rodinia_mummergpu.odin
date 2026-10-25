// Clean-room bounded MUMmerGPU maximal exact-match query; full source notice is package-local.
package rodinia_mummergpu

import "core:c"

MAX_REF :: 32
MAX_QUERY :: 32
ALPHABET :: 5
MAX_NODES :: 1 + MAX_REF * (MAX_REF + 3) / 2
MAX_MATCHES :: MAX_REF * MAX_QUERY

child_index :: proc(node, symbol: int) -> int { return node * ALPHABET + symbol }
suffix_less :: proc(reference: [^]i64, length, left, right: int) -> bool {
	a, b := left, right
	for a < length && b < length && reference[a] == reference[b] { a += 1; b += 1 }
	if a == length && b == length do return false
	if a == length do return false
	if b == length do return true
	return reference[a] < reference[b]
}
put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 do output[offset + byte] = u8(bits >> (8 * byte))
}

@(export)
rodinia_mummergpu :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 67 do return -1
	if input[0] < 1 || input[0] > MAX_REF || input[1] < 1 || input[1] > MAX_QUERY || input[2] < 1 || input[2] > MAX_QUERY do return -1
	ref_len, query_len, min_len := int(input[0]), int(input[1]), int(input[2])
	if length != c.size_t(3 + ref_len + query_len) do return -1
	reference: [MAX_REF]i64
	query: [MAX_QUERY]i64
	for i in 0 ..< ref_len { if input[3 + i] < 0 || input[3 + i] > 3 do return -1; reference[i] = input[3 + i] }
	for i in 0 ..< query_len { if input[3 + ref_len + i] < 0 || input[3 + ref_len + i] > 3 do return -1; query[i] = input[3 + ref_len + i] }

	children: [MAX_NODES * ALPHABET]int
	path_node: [MAX_REF * (MAX_REF + 1)]int
	suffix_order: [MAX_REF]int
	for i in 0 ..< MAX_NODES * ALPHABET do children[i] = -1
	for i in 0 ..< MAX_REF * (MAX_REF + 1) do path_node[i] = -1
	node_count := 1
	for start in 0 ..< ref_len {
		node, depth := 0, 0
		path_node[start * (MAX_REF + 1)] = 0
		for pos in start ..< ref_len {
			slot := child_index(node, int(reference[pos]))
			if children[slot] < 0 {
				fresh := node_count; node_count += 1; children[slot] = fresh
				for symbol in 0 ..< ALPHABET do children[child_index(fresh, symbol)] = -1
			}
			node = children[slot]; depth += 1
			path_node[start * (MAX_REF + 1) + depth] = node
		}
		terminal := child_index(node, 4)
		if children[terminal] < 0 {
			fresh := node_count; node_count += 1; children[terminal] = fresh
			for symbol in 0 ..< ALPHABET do children[child_index(fresh, symbol)] = -1
		}
	}
	for i in 0 ..< ref_len do suffix_order[i] = i
	for i in 1 ..< ref_len {
		key := suffix_order[i]; j := i
		for j > 0 && suffix_less(&reference[0], ref_len, key, suffix_order[j - 1]) { suffix_order[j] = suffix_order[j - 1]; j -= 1 }
		suffix_order[j] = key
	}

	records: [MAX_MATCHES * 3]i64
	match_count := 0
	for qstart in 0 ..< query_len {
		candidate: [MAX_REF]int
		for r in 0 ..< ref_len do candidate[r] = -1
		node, depth := 0, 0
		for {
			query_has_next := qstart + depth < query_len
			for rstart in 0 ..< ref_len {
				if path_node[rstart * (MAX_REF + 1) + depth] != node do continue
				suffix_ends := rstart + depth == ref_len
				if suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth] do candidate[rstart] = depth
			}
			if !query_has_next do break
			slot := child_index(node, int(query[qstart + depth]))
			if children[slot] < 0 do break
			node = children[slot]; depth += 1
		}
		for order in 0 ..< ref_len {
			rstart := suffix_order[order]; match_len := candidate[rstart]
			if match_len < min_len do continue
			if qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1] do continue
			records[3 * match_count] = i64(rstart + 1)
			records[3 * match_count + 1] = i64(qstart + 1)
			records[3 * match_count + 2] = i64(match_len)
			match_count += 1
		}
	}
	output_bytes := match_count * 24
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i in 0 ..< 3 * match_count do put_i64(output, i * 8, records[i])
	return i64(output_bytes)
}
