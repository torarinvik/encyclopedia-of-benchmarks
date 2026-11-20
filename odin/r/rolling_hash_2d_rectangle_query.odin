package rolling_hash_2d_rectangle_query

import "core:c"

MAX_H :: 32
MAX_W :: 32
MAX_Q :: 128
MAX_INPUT :: 1540
MAX_OUTPUT :: 1024
MODULUS :: i64(1_000_000_007)
ROW_BASE :: i64(31)
COL_BASE :: i64(37)

@(export)
rolling_hash_2d_rectangle_query :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
	h_value := input[0]
	w_value := input[1]
	q_value := input[2]
	if h_value < 1 || h_value > MAX_H || w_value < 1 || w_value > MAX_W || q_value < 1 || q_value > MAX_Q do return -1
	h := int(h_value)
	w := int(w_value)
	q := int(q_value)
	if length != c.size_t(3 + h*w + 4*q) do return -1
	query_offset := 3 + h*w
	for i := 0; i < h*w; i += 1 {
		if input[3+i] < 0 || input[3+i] > 255 do return -1
	}
	for i := 0; i < q; i += 1 {
		r0 := input[query_offset + 4*i]
		c0 := input[query_offset + 4*i + 1]
		r1 := input[query_offset + 4*i + 2]
		c1 := input[query_offset + 4*i + 3]
		if r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value do return -1
	}
	required := 8*q
	if output == nil || capacity < c.size_t(required) do return -2

	var row_power: [MAX_H+1]i64
	var col_power: [MAX_W+1]i64
	row_power[0] = 1
	col_power[0] = 1
	for i := 1; i <= h; i += 1 { row_power[i] = row_power[i-1] * ROW_BASE % MODULUS }
	for j := 1; j <= w; j += 1 { col_power[j] = col_power[j-1] * COL_BASE % MODULUS }
	var prefix: [MAX_H+1][MAX_W+1]i64
	for r := 1; r <= h; r += 1 {
		row_hash: i64 = 0
		for c := 1; c <= w; c += 1 {
			row_hash = (row_hash * COL_BASE + input[3 + (r-1)*w + c-1]) % MODULUS
			prefix[r][c] = (prefix[r-1][c] * ROW_BASE + row_hash) % MODULUS
		}
	}
	var staged: [MAX_OUTPUT]u8
	for i := 0; i < q; i += 1 {
		r0 := int(input[query_offset + 4*i])
		c0 := int(input[query_offset + 4*i + 1])
		r1 := int(input[query_offset + 4*i + 2])
		c1 := int(input[query_offset + 4*i + 3])
		rh := r1-r0
		cw := c1-c0
		value := prefix[r1][c1] - prefix[r0][c1] * row_power[rh] % MODULUS -
			prefix[r1][c0] * col_power[cw] % MODULUS +
			prefix[r0][c0] * row_power[rh] % MODULUS * col_power[cw] % MODULUS
		value %= MODULUS
		if value < 0 { value += MODULUS }
		bits := u64(value)
		for byte := 0; byte < 8; byte += 1 { staged[8*i+byte] = u8((bits >> (8*byte)) & 255) }
	}
	for i := 0; i < required; i += 1 { output[i] = staged[i] }
	return i64(required)
}
