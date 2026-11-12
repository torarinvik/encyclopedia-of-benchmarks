package point_set_range_frequency

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_VALUES :: MAX_N + MAX_Q
STRIDE :: MAX_N + 1
MAX_TREE :: MAX_VALUES * STRIDE
MAX_PARSEABLE_INPUT :: 2 + MAX_N + 4 * MAX_Q + 1
MAX_VALUE :: i64(1_000_000)

Operation :: struct { kind, a, b, c: i64 }

lowbit :: proc "contextless" (value: int) -> int { return value & -value }

lower_bound :: proc "contextless" (values: [^]i64, count: int, target: i64) -> int {
	mut left, right := 0, count
	for left < right {
		middle := left + (right-left)/2
		if values[middle] < target { left = middle+1 } else { right = middle }
	}
	return left
}

sort_unique :: proc "contextless" (values: [^]i64, count: int) -> int {
	for index := 1; index < count; index += 1 {
		value := values[index]
		mut position := index
		for position > 0 && values[position-1] > value {
			values[position] = values[position-1]
			position -= 1
		}
		values[position] = value
	}
	mut unique_count := 0
	for index := 0; index < count; index += 1 {
		if unique_count == 0 || values[index] != values[unique_count-1] {
			values[unique_count] = values[index]
			unique_count += 1
		}
	}
	return unique_count
}

fenwick_add :: proc "contextless" (tree: [^]i64, value_id, position, n: int, delta: i64) {
	mut index := position+1
	row := value_id*STRIDE
	for index <= n {
		tree[row+index] += delta
		index += lowbit(index)
	}
}

fenwick_prefix :: proc "contextless" (tree: [^]i64, value_id, count: int) -> i64 {
	mut index := count
	row := value_id*STRIDE
	mut total: i64 = 0
	for index > 0 {
		total += tree[row+index]
		index -= lowbit(index)
	}
	return total
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
point_set_range_frequency :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if 2+n > int(length) do return -1
	var values: [MAX_VALUES]i64
	var initial: [MAX_N]i64
	var operations: [MAX_Q]Operation
	mut value_count := 0
	for index := 0; index < n; index += 1 {
		value := input[2+index]
		if value < 0 || value > MAX_VALUE do return -1
		initial[index] = value
		values[value_count] = value
		value_count += 1
	}
	mut cursor, query_count := 2+n, 0
	for index := 0; index < q; index += 1 {
		if cursor >= int(length) do return -1
		kind := input[cursor]
		cursor += 1
		if kind == 0 {
			if cursor+2 > int(length) do return -1
			position, value := input[cursor], input[cursor+1]
			cursor += 2
			if position < 0 || position >= nv || value < 0 || value > MAX_VALUE do return -1
			operations[index] = Operation{kind, position, value, 0}
			values[value_count] = value
			value_count += 1
		} else if kind == 1 {
			if cursor+3 > int(length) do return -1
			left, right, value := input[cursor], input[cursor+1], input[cursor+2]
			cursor += 3
			if left < 0 || left > right || right > nv || value < 0 || value > MAX_VALUE do return -1
			operations[index] = Operation{kind, left, right, value}
			query_count += 1
		} else do return -1
	}
	if cursor != int(length) do return -1
	output_bytes := 8*query_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2

	unique_count := sort_unique(&values[0], value_count)
	var tree: [MAX_TREE]i64
	var current: [MAX_N]int
	for position := 0; position < n; position += 1 {
		current[position] = lower_bound(&values[0], unique_count, initial[position])
		fenwick_add(&tree[0], current[position], position, n, 1)
	}
	mut answer := 0
	for index := 0; index < q; index += 1 {
		op := operations[index]
		if op.kind == 0 {
			position := int(op.a)
			next := lower_bound(&values[0], unique_count, op.b)
			if current[position] != next {
				fenwick_add(&tree[0], current[position], position, n, -1)
				fenwick_add(&tree[0], next, position, n, 1)
				current[position] = next
			}
		} else {
			id := lower_bound(&values[0], unique_count, op.c)
			mut count: i64 = 0
			if id < unique_count && values[id] == op.c {
				count = fenwick_prefix(&tree[0], id, int(op.b))-fenwick_prefix(&tree[0], id, int(op.a))
			}
			store_i64_le(output, answer*8, count)
			answer += 1
		}
	}
	return i64(output_bytes)
}
