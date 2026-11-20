package bagwell_functional_hash_list

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, at: usize, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[at + usize(b)] = u8((bits >> u64(8*b)) & 255) }
}

@(export)
bagwell_functional_hash_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 131 { return -1 }
	nv := input[0]
	if nv < 0 || nv > 32 { return -1 }
	n := usize(nv)
	q_at := 1 + 2*n
	if q_at >= length { return -1 }
	qv := input[q_at]
	if qv < 1 || qv > 32 { return -1 }
	q := usize(qv)
	query_at := q_at + 1
	if length != c.size_t(2 + 2*n + 2*q) { return -1 }
	for i := usize(0); i < n; i += 1 {
		if input[1+2*i] < -2147483648 || input[1+2*i] > 2147483647 ||
			input[2+2*i] < -2147483648 || input[2+2*i] > 2147483647 { return -1 }
	}
	for j := usize(0); j < q; j += 1 {
		root, key := input[query_at+2*j], input[query_at+2*j+1]
		if root < 0 || root > nv || key < -2147483648 || key > 2147483647 { return -1 }
	}
	output_bytes := 8*q
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }

	keys: [56]i64
	values: [56]i64
	next: [56]int
	heads: [56]int
	prev: [3]int = {-1, -1, -1}
	root_block: [33]int
	root_offset: [33]int
	for i := 0; i < 56; i += 1 { next[i] = -1; heads[i] = -1 }
	for i := 0; i < 33; i += 1 { root_block[i] = -1; root_offset[i] = -1 }
	current := 0
	for i := 0; i < int(n); i += 1 {
		if i == 8 || i == 24 { prev[current+1] = current; current += 1 }
		start := if current == 0 { 0 } else if current == 1 { 8 } else { 24 }
		side := if current == 0 { 8 } else if current == 1 { 16 } else { 32 }
		offset := i - start
		slot := start + offset
		hash := u32(input[1+2*usize(i)])
		bucket_slot := start + int(hash & u32(side-1))
		keys[slot] = input[1+2*usize(i)]
		values[slot] = input[2+2*usize(i)]
		next[slot] = heads[bucket_slot]
		heads[bucket_slot] = offset
		root_block[i+1] = current
		root_offset[i+1] = offset
	}
	for j := usize(0); j < q; j += 1 {
		root := int(input[query_at+2*j])
		key := input[query_at+2*j+1]
		block, limit := root_block[root], root_offset[root]
		answer := i64(-9223372036854775807) - 1
		if block >= 0 {
			hash := u32(key)
			first := true
			for block >= 0 && answer == i64(-9223372036854775807)-1 {
				start := if block == 0 { 0 } else if block == 1 { 8 } else { 24 }
			side := if block == 0 { 8 } else if block == 1 { 16 } else { 32 }
				bucket_slot := start + int(hash & u32(side-1))
				chain := heads[bucket_slot]
				for chain >= 0 {
					slot := start + chain
					if (!first || chain <= limit) && keys[slot] == key { answer = values[slot]; break }
					chain = next[slot]
				}
				block = prev[block]
				first = false
			}
		}
		put_i64_le(output, 8*j, answer)
	}
	return i64(output_bytes)
}
