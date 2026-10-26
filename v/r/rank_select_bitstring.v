module rank_select_bitstring

const max_bits = 63
const max_blocks = 8
const max_queries = 16
const max_input = 35
const max_output_bytes = 128

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'rank_select_bitstring']
pub fn rank_select_bitstring(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value, packed_value, query_value := input[0], input[1], input[2]
		if n_value < 1 || n_value > max_bits || packed_value < 0 || query_value < 0 || query_value > max_queries { return -1 }
		n, queries := int(n_value), int(query_value)
		bits := u64(packed_value)
		if (bits >> u64(n)) != 0 || length != usize(3 + 2 * queries) { return -1 }
		block_count := (n + 7) / 8
		mut prefix := [max_blocks + 1]i64{init: 0}
		for block in 0 .. block_count {
			prefix[block + 1] = prefix[block]
			end := if 8 * block + 8 < n { 8 * block + 8 } else { n }
			for pos in 8 * block .. end { prefix[block + 1] += i64((bits >> u64(pos)) & 1) }
		}
		mut answers := [max_queries]i64{init: 0}
		for query in 0 .. queries {
			op, index_value := input[3 + 2*query], input[4 + 2*query]
			if (op != 0 && op != 1) || index_value < 1 || (op == 0 && index_value > n_value) || (op == 1 && index_value > max_bits + 1) { return -1 }
			index := int(index_value)
			if op == 0 {
				full_blocks, remainder := index / 8, index % 8
				mut answer := prefix[full_blocks]
				for pos in 8 * full_blocks .. 8 * full_blocks + remainder { answer += i64((bits >> u64(pos)) & 1) }
				answers[query] = answer
			} else {
				mut block := 0
				for block < block_count && prefix[block + 1] < i64(index) { block++ }
				answers[query] = -1
				if block < block_count {
					mut remaining := index - int(prefix[block])
					end := if 8 * block + 8 < n { 8 * block + 8 } else { n }
					for pos in 8 * block .. end {
						if ((bits >> u64(pos)) & 1) != 0 {
							remaining--
							if remaining == 0 { answers[query] = i64(pos + 1); break }
						}
					}
				}
			}
		}
		output_bytes := 8 * queries
		if output == nil || capacity < output_bytes { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		for query in 0 .. queries { store_i64_le(mut staged[..], 8 * query, answers[query]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
