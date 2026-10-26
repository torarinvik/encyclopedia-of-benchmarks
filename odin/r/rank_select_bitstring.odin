package rank_select_bitstring

import "core:c"

MAX_BITS :: 63
MAX_BLOCKS :: 8
MAX_QUERIES :: 16
MAX_INPUT :: 35
MAX_OUTPUT_BYTES :: 128

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
rank_select_bitstring :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_value, packed_value, query_value := input[0], input[1], input[2]
	if n_value < 1 || n_value > MAX_BITS || packed_value < 0 || query_value < 0 || query_value > MAX_QUERIES do return -1
	n, queries := int(n_value), int(query_value)
	bits := u64(packed_value)
	if bits >> u64(n) != 0 || length != c.size_t(3 + 2*queries) do return -1
	block_count := (n + 7) / 8
	prefix: [MAX_BLOCKS+1]i64
	for block := 0; block < block_count; block += 1 {
		prefix[block+1] = prefix[block]
		end := min(n, 8*block+8)
		for pos := 8*block; pos < end; pos += 1 { prefix[block+1] += i64((bits >> u64(pos)) & 1) }
	}
	answers: [MAX_QUERIES]i64
	for query := 0; query < queries; query += 1 {
		op, index_value := input[3+2*query], input[4+2*query]
		if (op != 0 && op != 1) || index_value < 1 || (op == 0 && index_value > n_value) || (op == 1 && index_value > MAX_BITS + 1) do return -1
		index := int(index_value)
		if op == 0 {
			full_blocks, remainder := index / 8, index % 8
			answer := prefix[full_blocks]
			for pos := 8*full_blocks; pos < 8*full_blocks+remainder; pos += 1 { answer += i64((bits >> u64(pos)) & 1) }
			answers[query] = answer
		} else {
			block := 0
			for block < block_count && prefix[block+1] < i64(index) { block += 1 }
			answers[query] = -1
			if block < block_count {
				remaining := index - int(prefix[block])
				end := min(n, 8*block+8)
				for pos := 8*block; pos < end; pos += 1 {
					if (bits >> u64(pos)) & 1 != 0 { remaining -= 1; if remaining == 0 { answers[query] = i64(pos+1); break } }
				}
			}
		}
	}
	output_bytes := 8*queries
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for query := 0; query < queries; query += 1 { store_i64_le(&staged[0], 8*query, answers[query]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
