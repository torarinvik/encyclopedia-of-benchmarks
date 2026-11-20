package mo_with_modifications

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT_LENGTH :: 258

Query :: struct {
	left: int,
	right: int,
	time: int,
	ordinal: int,
}

Change :: struct {
	position: int,
	before_value: int,
	after_value: int,
}

Window :: struct {
	values: [MAX_N]int,
	frequencies: [16]int,
	distinct_count: int,
	left: int,
	right: int,
}

add_value :: proc(window: ^Window, position: int) {
	value := window.values[position]
	if window.frequencies[value] == 0 do window.distinct_count += 1
	window.frequencies[value] += 1
}

remove_value :: proc(window: ^Window, position: int) {
	value := window.values[position]
	window.frequencies[value] -= 1
	if window.frequencies[value] == 0 do window.distinct_count -= 1
}

replace_value :: proc(window: ^Window, position, new_value: int) {
	if position >= window.left && position <= window.right do remove_value(window, position)
	window.values[position] = new_value
	if position >= window.left && position <= window.right do add_value(window, position)
}

query_before :: proc(a, b: Query, block_size: int) -> bool {
	left_block_a, left_block_b := a.left / block_size, b.left / block_size
	if left_block_a != left_block_b do return left_block_a < left_block_b
	right_block_a, right_block_b := a.right / block_size, b.right / block_size
	if right_block_a != right_block_b do return right_block_a < right_block_b
	if a.time != b.time do return a.time < b.time
	return a.ordinal < b.ordinal
}

@(export)
mo_with_modifications :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	n64, q64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q || length != c.size_t(2 + n64 + 3 * q64) do return -1
	n, q := int(n64), int(q64)
	var initial: [MAX_N]int
	for i := 0; i < n; i += 1 {
		value := input[2+i]
		if value < 0 || value > 15 do return -1
		initial[i] = int(value)
	}
	operation_offset := 2 + n
	for i := 0; i < q; i += 1 {
		op, first, second := input[operation_offset+3*i], input[operation_offset+3*i+1], input[operation_offset+3*i+2]
		if op == 0 {
			if first < 0 || first >= n64 || second < 0 || second > 15 do return -1
		} else if op == 1 {
			if first < 0 || second < first || second >= n64 do return -1
		} else do return -1
	}

	parse_state := initial
	var changes: [MAX_Q]Change
	var queries: [MAX_Q]Query
	change_count, query_count := 0, 0
	for i := 0; i < q; i += 1 {
		op := input[operation_offset+3*i]
		first, second := int(input[operation_offset+3*i+1]), int(input[operation_offset+3*i+2])
		if op == 0 {
			changes[change_count] = Change{position = first, before_value = parse_state[first], after_value = second}
			parse_state[first] = second
			change_count += 1
		} else {
			queries[query_count] = Query{left = first, right = second, time = change_count, ordinal = query_count}
			query_count += 1
		}
	}

	block_size := 1
	for (block_size+1)*(block_size+1)*(block_size+1) <= n*n do block_size += 1
	for i := 1; i < query_count; i += 1 {
		current := queries[i]
		position := i
		for position > 0 && query_before(current, queries[position-1], block_size) {
			queries[position] = queries[position-1]
			position -= 1
		}
		queries[position] = current
	}

	window := Window{values = initial, left = 0, right = -1}
	current_time := 0
	var answers: [MAX_Q]int
	for sorted := 0; sorted < query_count; sorted += 1 {
		query := queries[sorted]
		for current_time < query.time {
			change := changes[current_time]
			replace_value(&window, change.position, change.after_value)
			current_time += 1
		}
		for current_time > query.time {
			current_time -= 1
			change := changes[current_time]
			replace_value(&window, change.position, change.before_value)
		}
		for window.left > query.left { window.left -= 1; add_value(&window, window.left) }
		for window.right < query.right { window.right += 1; add_value(&window, window.right) }
		for window.left < query.left { remove_value(&window, window.left); window.left += 1 }
		for window.right > query.right { remove_value(&window, window.right); window.right -= 1 }
		answers[query.ordinal] = window.distinct_count
	}

	checksum := i64(0)
	for ordinal := 0; ordinal < query_count; ordinal += 1 {
		checksum += i64(ordinal+1) * i64(answers[ordinal]+1)
	}
	return checksum
}
