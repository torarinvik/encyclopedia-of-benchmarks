package rat_maze

import "core:c"

MAX_N :: 8
MAX_INPUT_WORDS :: 1 + MAX_N * MAX_N
MAX_OUTPUT_BYTES :: 4 * (1 + MAX_N * MAX_N)

search_path :: proc(input: [^]i32, path: [^]i32, n, row, col: int) -> bool {
	index := row*n + col
	path[index] = 1
	if row == n-1 && col == n-1 do return true
	if col+1 < n && input[1+index+1] == 1 && search_path(input, path, n, row, col+1) do return true
	if row+1 < n && input[1+index+n] == 1 && search_path(input, path, n, row+1, col) do return true
	path[index] = 0
	return false
}

put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
rat_maze :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	cells := n*n
	if int(length) != 1+cells || input[1] != 1 do return -1
	for i := 0; i < cells; i += 1 { if input[1+i] < 0 || input[1+i] > 1 do return -1 }
	path: [MAX_N*MAX_N]i32
	found := search_path(input, &path[0], n, 0, 0)
	word_count := 1
	if found do word_count = 1 + cells
	bytes := word_count*4
	if output == nil || capacity < c.size_t(bytes) do return -2
	buffer: [MAX_OUTPUT_BYTES]u8
	put_i32_le(&buffer[0], 0, i32(if found { 1 } else { 0 }))
	if found {
		for i := 0; i < cells; i += 1 { put_i32_le(&buffer[0], (i+1)*4, path[i]) }
	}
	for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
	return i64(bytes)
}
