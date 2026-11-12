package range_affine_point_get

import "core:c"

MAX_N :: 256
MAX_Q :: 256
MAX_BASE :: 256
MAX_TREE :: 2 * MAX_BASE
MAX_PARSEABLE_INPUT :: 2 + MAX_N + 5 * MAX_Q + 1
MOD :: i64(998_244_353)

Operation :: struct { kind, left, right, multiplier, offset: i64 }

apply_tag :: proc "contextless" (mul, add: [^]i64, node: int, multiplier, offset: i64) {
	add[node] = (multiplier * add[node] + offset) % MOD
	mul[node] = (multiplier * mul[node]) % MOD
}

push :: proc "contextless" (mul, add: [^]i64, node: int) {
	if mul[node] != 1 || add[node] != 0 {
		multiplier, offset := mul[node], add[node]
		apply_tag(mul, add, 2*node, multiplier, offset)
		apply_tag(mul, add, 2*node+1, multiplier, offset)
		mul[node], add[node] = 1, 0
	}
}

range_apply :: proc "contextless" (mul, add: [^]i64, node, segment_left, segment_right,
		left, right: int, multiplier, offset: i64) {
	if right <= segment_left || segment_right <= left do return
	if left <= segment_left && segment_right <= right {
		apply_tag(mul, add, node, multiplier, offset)
		return
	}
	push(mul, add, node)
	middle := segment_left + (segment_right-segment_left)/2
	range_apply(mul, add, 2*node, segment_left, middle, left, right, multiplier, offset)
	range_apply(mul, add, 2*node+1, middle, segment_right, left, right, multiplier, offset)
}

point_get :: proc "contextless" (mul, add, initial: [^]i64, node,
		segment_left, segment_right, index: int) -> i64 {
	if segment_right-segment_left == 1 do return (mul[node]*initial[index]+add[node]) % MOD
	push(mul, add, node)
	middle := segment_left + (segment_right-segment_left)/2
	if index < middle do return point_get(mul, add, initial, 2*node, segment_left, middle, index)
	return point_get(mul, add, initial, 2*node+1, middle, segment_right, index)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
range_affine_point_get :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if 2+n > int(length) do return -1
	var initial: [MAX_N]i64
	var operations: [MAX_Q]Operation
	for index := 0; index < n; index += 1 {
		initial[index] = input[2+index]
		if initial[index] < 0 || initial[index] >= MOD do return -1
	}
	cursor, query_count := 2+n, 0
	for index := 0; index < q; index += 1 {
		if cursor >= int(length) do return -1
		kind := input[cursor]
		cursor += 1
		if kind == 0 {
			if cursor+4 > int(length) do return -1
			left, right := input[cursor], input[cursor+1]
			multiplier, offset := input[cursor+2], input[cursor+3]
			cursor += 4
			if left < 0 || left >= right || right > nv || multiplier < 1 || multiplier >= MOD || offset < 0 || offset >= MOD do return -1
			operations[index] = Operation{kind, left, right, multiplier, offset}
		} else if kind == 1 {
			if cursor >= int(length) do return -1
			point := input[cursor]
			cursor += 1
			if point < 0 || point >= nv do return -1
			operations[index] = Operation{kind, point, 0, 0, 0}
			query_count += 1
		} else do return -1
	}
	if cursor != int(length) do return -1
	output_bytes := 8*query_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
	base := 1
	for base < n { base *= 2 }
	var mul, add: [MAX_TREE]i64
	for node := 0; node < MAX_TREE; node += 1 { mul[node] = 1 }
	answer := 0
	for index := 0; index < q; index += 1 {
		op := operations[index]
		if op.kind == 0 {
			range_apply(&mul[0], &add[0], 1, 0, base, int(op.left), int(op.right), op.multiplier, op.offset)
		} else {
			value := point_get(&mul[0], &add[0], &initial[0], 1, 0, base, int(op.left))
			store_i64_le(output, 8*answer, value)
			answer += 1
		}
	}
	return i64(output_bytes)
}
