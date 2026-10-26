module non_shared_edges

const max_leaves = 8
const max_edges = 13
const max_input = 27

fn store_i64_le(mut output []u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
}

fn bit_count(value u64, n int) int {
	mut count := 0
	for bit in 0 .. n { count += int((value >> bit) & 1) }
	return count
}

fn valid_tree(input &i64, offset int, n int, edges int) bool {
	mut masks := [max_edges]u64{init: 0}
	mut internal := [max_edges]u64{init: 0}
	mut internal_count := 0
	universe := (u64(1) << n) - 1
	unsafe {
		for edge in 0 .. edges {
			raw := input[offset + edge]
			if raw <= 0 || u64(raw) >= universe || (raw & 1) != 0 { return false }
			masks[edge] = u64(raw)
			for earlier in 0 .. edge { if masks[earlier] == masks[edge] { return false } }
			size := bit_count(masks[edge], n)
			if size == 1 || size == n - 1 {
				if size == n - 1 && masks[edge] != (universe ^ 1) { return false }
			} else if size >= 2 && size <= n - 2 {
				internal[internal_count] = masks[edge]
				internal_count++
			} else { return false }
		}
		if internal_count != n - 3 { return false }
		for leaf in 1 .. n {
			pendant := u64(1) << leaf
			mut found := 0
			for edge in 0 .. edges { if masks[edge] == pendant { found++ } }
			if found != 1 { return false }
		}
		mut root_pendant := 0
		for edge in 0 .. edges { if masks[edge] == (universe ^ 1) { root_pendant++ } }
		if root_pendant != 1 { return false }
		for i in 0 .. internal_count {
			for j in i + 1 .. internal_count {
				intersection := internal[i] & internal[j]
				if intersection != 0 && intersection != internal[i] && intersection != internal[j] { return false }
			}
		}
	}
	return true
}

@[export: 'non_shared_edges']
pub fn non_shared_edges(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > max_input { return -1 }
		leaf_value := input[0]
		if leaf_value < 3 || leaf_value > max_leaves { return -1 }
		leaves, edges := int(leaf_value), 2 * int(leaf_value) - 3
		if length != usize(1 + 2 * edges) { return -1 }
		second := 1 + edges
		if !valid_tree(input, 1, leaves, edges) || !valid_tree(input, second, leaves, edges) { return -1 }
		mut shared := i64(0)
		for left in 0 .. edges {
			for right in 0 .. edges {
				if input[1 + left] == input[second + right] { shared++; break }
			}
		}
		if output == nil || capacity < 8 { return -2 }
		mut staged := [8]u8{init: 0}
		store_i64_le(mut staged[..], i64(edges) - shared)
		for byte in 0 .. 8 { output[byte] = staged[byte] }
		return 8
	}
}
