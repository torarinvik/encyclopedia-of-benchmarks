// Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt.
module rodinia_mummergpu

const max_ref = 32
const max_query = 32
const alphabet = 5
const max_nodes = 1 + max_ref * (max_ref + 3) / 2
const max_matches = max_ref * max_query

fn suffix_less(reference []i64, ref_length int, left int, right int) bool {
	mut a := left
	mut b := right
	for a < ref_length && b < ref_length && reference[a] == reference[b] { a++; b++ }
	if a == ref_length && b == ref_length { return false }
	if a == ref_length { return false }
	if b == ref_length { return true }
	return reference[a] < reference[b]
}

fn put_i64(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte := 0; byte < 8; byte++ { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'rodinia_mummergpu']
pub fn rodinia_mummergpu(input &i64, length usize, output &u8, capacity usize) i64 {
	if length < 5 || length > 3 + max_ref + max_query || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_ref || input[1] < 1 || input[1] > max_query || input[2] < 1 || input[2] > max_query { return -1 }
		ref_length := int(input[0]); query_length := int(input[1]); min_length := int(input[2])
		if length != usize(3 + ref_length + query_length) { return -1 }
		mut reference := []i64{len: max_ref}
		mut query := []i64{len: max_query}
		for i := 0; i < ref_length; i++ { code := input[3 + i]; if code < 0 || code > 3 { return -1 }; reference[i] = code }
		for i := 0; i < query_length; i++ { code := input[3 + ref_length + i]; if code < 0 || code > 3 { return -1 }; query[i] = code }

		mut children := []int{len: max_nodes * alphabet}
		mut path_node := []int{len: max_ref * (max_ref + 1)}
		mut suffix_order := []int{len: max_ref}
		for i := 0; i < children.len; i++ { children[i] = -1 }
		for i := 0; i < path_node.len; i++ { path_node[i] = -1 }
		mut node_count := 1
		for start := 0; start < ref_length; start++ {
			mut node := 0; mut depth := 0
			path_node[start * (max_ref + 1)] = 0
			for pos := start; pos < ref_length; pos++ {
				slot := node * alphabet + int(reference[pos])
				if children[slot] < 0 {
					fresh := node_count; node_count++
					children[slot] = fresh
					for symbol := 0; symbol < alphabet; symbol++ { children[fresh * alphabet + symbol] = -1 }
				}
				node = children[slot]; depth++
				path_node[start * (max_ref + 1) + depth] = node
			}
			terminal := node * alphabet + 4
			if children[terminal] < 0 {
				fresh := node_count; node_count++
				children[terminal] = fresh
				for symbol := 0; symbol < alphabet; symbol++ { children[fresh * alphabet + symbol] = -1 }
			}
		}
		for i := 0; i < ref_length; i++ { suffix_order[i] = i }
		for i := 1; i < ref_length; i++ {
			key := suffix_order[i]; mut j := i
			for j > 0 && suffix_less(reference, ref_length, key, suffix_order[j - 1]) { suffix_order[j] = suffix_order[j - 1]; j-- }
			suffix_order[j] = key
		}

		mut records := []i64{len: max_matches * 3}
		mut match_count := 0
		for qstart := 0; qstart < query_length; qstart++ {
			mut candidate := []int{len: max_ref}
			for rstart := 0; rstart < ref_length; rstart++ { candidate[rstart] = -1 }
			mut node := 0; mut depth := 0
			for {
				query_has_next := qstart + depth < query_length
				for rstart := 0; rstart < ref_length; rstart++ {
					if path_node[rstart * (max_ref + 1) + depth] != node { continue }
					suffix_ends := rstart + depth == ref_length
					if suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth] { candidate[rstart] = depth }
				}
				if !query_has_next { break }
				slot := node * alphabet + int(query[qstart + depth])
				if children[slot] < 0 { break }
				node = children[slot]; depth++
			}
			for order := 0; order < ref_length; order++ {
				rstart := suffix_order[order]; match_length := candidate[rstart]
				if match_length < min_length { continue }
				if qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1] { continue }
				records[3 * match_count] = i64(rstart + 1)
				records[3 * match_count + 1] = i64(qstart + 1)
				records[3 * match_count + 2] = i64(match_length)
				match_count++
			}
		}
		output_bytes := match_count * 24
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i := 0; i < 3 * match_count; i++ { put_i64(output, i * 8, records[i]) }
		return i64(output_bytes)
	}
}
