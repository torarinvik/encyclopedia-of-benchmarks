package prefix_substring_lcs

import "core:c"

MAX_M :: 32
MAX_N :: 32
MAX_Q :: 64
STRIDE :: MAX_N + 1
MAX_INPUT :: 3 + MAX_M + MAX_N + 3 * MAX_Q

Query :: struct { a, b, c: int }

lowbit :: proc "contextless" (value: int) -> int { return value & -value }

fenwick_add :: proc "contextless" (tree: [^]int, position, count: int) {
	index := position + 1
	for index <= count {
		tree[index] += 1
		index += lowbit(index)
	}
}

fenwick_prefix :: proc "contextless" (tree: [^]int, exclusive: int) -> int {
	mut total, index := 0, exclusive
	for index > 0 {
		total += tree[index]
		index -= lowbit(index)
	}
	return total
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
prefix_substring_lcs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	if input[0] < 1 || input[0] > MAX_M || input[1] < 1 || input[1] > MAX_N ||
		input[2] < 1 || input[2] > MAX_Q do return -1
	m, n, q := int(input[0]), int(input[1]), int(input[2])
	if int(length) != 3+m+n+3*q do return -1

	var s: [MAX_M]int
	var t: [MAX_N]int
	mut offset := 3
	for index := 0; index < m; index += 1 {
		code := input[offset]
		if code < 97 || code > 122 do return -1
		s[index] = int(code)
		offset += 1
	}
	for index := 0; index < n; index += 1 {
		code := input[offset]
		if code < 97 || code > 122 do return -1
		t[index] = int(code)
		offset += 1
	}
	var queries: [MAX_Q]Query
	var query_head: [STRIDE*STRIDE]int
	var query_next: [MAX_Q]int
	for index := 0; index < STRIDE*STRIDE; index += 1 { query_head[index] = -1 }
	for index := 0; index < q; index += 1 {
		a, b, c_value := input[offset], input[offset+1], input[offset+2]
		if a < 0 || a > i64(m) || b < 0 || b > c_value || c_value > i64(n) do return -1
		queries[index] = Query{int(a), int(b), int(c_value)}
		key := queries[index].a*STRIDE + queries[index].b
		query_next[index] = query_head[key]
		query_head[key] = index
		offset += 3
	}
	output_bytes := 8*q
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	var horizontal: [STRIDE][STRIDE]int
	var vertical: [STRIDE][STRIDE]int
	for j := 0; j <= n; j += 1 { horizontal[0][j] = j }
	for i := 1; i <= m; i += 1 {
		for j := 1; j <= n; j += 1 {
			above, left := horizontal[i-1][j], vertical[i][j-1]
			if s[i-1] == t[j-1] {
				horizontal[i][j], vertical[i][j] = left, above
			} else {
				if above > left { horizontal[i][j] = above } else { horizontal[i][j] = left }
				if above < left { vertical[i][j] = above } else { vertical[i][j] = left }
			}
		}
	}
	var answers: [MAX_Q]int
	for a := 0; a <= m; a += 1 {
		var value_head: [STRIDE]int
		var value_next: [STRIDE]int
		for value := 0; value <= n; value += 1 { value_head[value] = -1 }
		for position := 0; position <= n; position += 1 {
			value := horizontal[a][position]
			value_next[position] = value_head[value]
			value_head[value] = position
		}
		var fenwick: [STRIDE+1]int
		for b := 0; b <= n; b += 1 {
			for position := value_head[b]; position >= 0; position = value_next[position] {
				fenwick_add(&fenwick[0], position, n+1)
			}
			for qi := query_head[a*STRIDE+b]; qi >= 0; qi = query_next[qi] {
				query := queries[qi]
				answers[qi] = fenwick_prefix(&fenwick[0], query.c+1) - fenwick_prefix(&fenwick[0], query.b+1)
			}
		}
	}
	for index := 0; index < q; index += 1 { store_i64_le(output, 8*index, i64(answers[index])) }
	return i64(output_bytes)
}
