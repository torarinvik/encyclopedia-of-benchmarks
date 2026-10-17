package mo

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_VALUE :: 255
MAX_PARSEABLE_INPUT_WORDS :: 2 + MAX_N + 2 * MAX_Q + 1
MAX_OUTPUT_BYTES :: 4 * MAX_Q

Query :: struct { left, right, index: int }

ceil_sqrt :: proc(n: int) -> int {
	block := 1
	for block*block < n { block += 1 }
	return block
}

before :: proc(a, b: Query, block_size: int) -> bool {
	a_block, b_block := a.left/block_size, b.left/block_size
	if a_block != b_block do return a_block < b_block
	return a.right < b.right
}

put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
mo :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_WORDS) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	q_offset := 1+n
	if int(length) <= q_offset do return -1
	q_raw := input[q_offset]
	if q_raw < 0 || q_raw > MAX_Q do return -1
	q_count := int(q_raw)
	if int(length) != q_offset+1+2*q_count do return -1
	for i := 0; i < n; i += 1 { if input[1+i] < 0 || input[1+i] > MAX_VALUE do return -1 }
	var queries: [MAX_Q]Query
	for i := 0; i < q_count; i += 1 {
		left_raw, right_raw := input[q_offset+1+2*i], input[q_offset+2+2*i]
		if left_raw < 1 || right_raw < left_raw || right_raw > n_raw do return -1
		queries[i] = { int(left_raw-1), int(right_raw-1), i }
	}
	bytes := 4*q_count
	if output == nil || capacity < c.size_t(bytes) do return -2
	block_size := ceil_sqrt(n)
	for i := 1; i < q_count; i += 1 {
		value := queries[i]
		j := i
		for j > 0 && before(value, queries[j-1], block_size) { queries[j] = queries[j-1]; j -= 1 }
		queries[j] = value
	}
	var frequencies: [MAX_VALUE+1]i32
	var answers: [MAX_Q]i32
	distinct: i32 = 0
	left, right := 0, 0
	for i := 0; i < q_count; i += 1 {
		query := queries[i]
		for left < query.left { value := int(input[1+left]); left += 1; frequencies[value] -= 1; if frequencies[value] == 0 do distinct -= 1 }
		for left > query.left { left -= 1; value := int(input[1+left]); frequencies[value] += 1; if frequencies[value] == 1 do distinct += 1 }
		for right <= query.right { value := int(input[1+right]); frequencies[value] += 1; if frequencies[value] == 1 do distinct += 1; right += 1 }
		for right > query.right+1 { right -= 1; value := int(input[1+right]); frequencies[value] -= 1; if frequencies[value] == 0 do distinct -= 1 }
		answers[query.index] = distinct
	}
	if bytes == 0 do return 0
	var buffer: [MAX_OUTPUT_BYTES]u8
	for i := 0; i < q_count; i += 1 { put_i32_le(&buffer[0], 4*i, answers[i]) }
	for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
	return i64(bytes)
}
