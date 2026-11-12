package rectangle_add_point_get

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_RECTANGLES :: MAX_N + MAX_Q
MAX_COORDS :: 2 * MAX_RECTANGLES
MAX_CORNERS :: 4 * MAX_RECTANGLES
MAX_PARSEABLE_INPUT :: 2 + 5 * MAX_N + 6 * MAX_Q + 1
MAX_COORD :: i64(1_000_000)
MAX_WEIGHT :: i64(1_000_000)

Rectangle :: struct { left, down, right, up, weight: i64 }
Operation :: struct { kind, a, b, c, d, e: i64 }

lowbit :: proc "contextless" (value: int) -> int { return value & -value }

lower_bound_i64 :: proc "contextless" (values: [^]i64, count: int, target: i64) -> int {
	mut left, right := 0, count
	for left < right {
		middle := left + (right-left)/2
		if values[middle] < target { left = middle+1 } else { right = middle }
	}
	return left
}

upper_bound_i64 :: proc "contextless" (values: [^]i64, count: int, target: i64) -> int {
	mut left, right := 0, count
	for left < right {
		middle := left + (right-left)/2
		if values[middle] <= target { left = middle+1 } else { right = middle }
	}
	return left
}

lower_bound_int :: proc "contextless" (values: [^]int, count, target: int) -> int {
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

register_event :: proc "contextless" (xs, ys: [^]i64, x_count, y_count: int,
		present: [^]bool, x, y: i64) {
	mut outer := lower_bound_i64(xs, x_count, x)+1
	rank := lower_bound_i64(ys, y_count, y)
	for outer <= x_count {
		present[outer*MAX_COORDS+rank] = true
		outer += lowbit(outer)
	}
}

register_rectangle :: proc "contextless" (xs, ys: [^]i64, x_count, y_count: int,
		present: [^]bool, rectangle: Rectangle) {
	register_event(xs, ys, x_count, y_count, present, rectangle.left, rectangle.down)
	register_event(xs, ys, x_count, y_count, present, rectangle.right, rectangle.down)
	register_event(xs, ys, x_count, y_count, present, rectangle.left, rectangle.up)
	register_event(xs, ys, x_count, y_count, present, rectangle.right, rectangle.up)
}

fenwick_add :: proc "contextless" (tree: [^]i64, y_values: [^]int, y_counts: [^]int,
		xs: [^]i64, x_count: int, ys: [^]i64, y_count: int,
		x, y, weight: i64) {
	mut outer := lower_bound_i64(xs, x_count, x)+1
	y_rank := lower_bound_i64(ys, y_count, y)
	for outer <= x_count {
		row := outer*MAX_COORDS
		mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_rank)+1
		for inner <= y_counts[outer] {
			tree[outer*(MAX_COORDS+1)+inner] += weight
			inner += lowbit(inner)
		}
		outer += lowbit(outer)
	}
}

apply_rectangle :: proc "contextless" (tree: [^]i64, y_values: [^]int, y_counts: [^]int,
		xs: [^]i64, x_count: int, ys: [^]i64, y_count: int, rectangle: Rectangle) {
	fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.left, rectangle.down, rectangle.weight)
	fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.right, rectangle.down, -rectangle.weight)
	fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.left, rectangle.up, -rectangle.weight)
	fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.right, rectangle.up, rectangle.weight)
}

prefix_sum :: proc "contextless" (tree: [^]i64, y_values: [^]int, y_counts: [^]int,
		xs: [^]i64, x_count: int, ys: [^]i64, y_count: int,
		x_limit, y_limit: i64) -> i64 {
	mut outer := upper_bound_i64(xs, x_count, x_limit)
	y_limit_rank := upper_bound_i64(ys, y_count, y_limit)
	mut total := i64(0)
	for outer > 0 {
		row := outer*MAX_COORDS
		mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_limit_rank)
		for inner > 0 {
			total += tree[outer*(MAX_COORDS+1)+inner]
			inner -= lowbit(inner)
		}
		outer -= lowbit(outer)
	}
	return total
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
rectangle_add_point_get :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 1 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	var initial: [MAX_N]Rectangle
	var operations: [MAX_Q]Operation
	var all_x, all_y: [MAX_CORNERS]i64
	rectangle_count, cursor := 0, 2
	for index := 0; index < n; index += 1 {
		if cursor + 5 > int(length) do return -1
		rectangle := Rectangle{input[cursor], input[cursor+1], input[cursor+2], input[cursor+3], input[cursor+4]}
		cursor += 5
		if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
			rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
			rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT do return -1
		initial[index] = rectangle
		all_x[4*rectangle_count], all_y[4*rectangle_count] = rectangle.left, rectangle.down
		all_x[4*rectangle_count+1], all_y[4*rectangle_count+1] = rectangle.right, rectangle.down
		all_x[4*rectangle_count+2], all_y[4*rectangle_count+2] = rectangle.left, rectangle.up
		all_x[4*rectangle_count+3], all_y[4*rectangle_count+3] = rectangle.right, rectangle.up
		rectangle_count += 1
	}
	for index := 0; index < q; index += 1 {
		if cursor >= int(length) do return -1
		kind := input[cursor]
		cursor += 1
		if kind == 0 {
			if cursor + 5 > int(length) do return -1
			rectangle := Rectangle{input[cursor], input[cursor+1], input[cursor+2], input[cursor+3], input[cursor+4]}
			cursor += 5
			if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
				rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
				rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT do return -1
			operations[index] = {0, rectangle.left, rectangle.down, rectangle.right, rectangle.up, rectangle.weight}
			all_x[4*rectangle_count], all_y[4*rectangle_count] = rectangle.left, rectangle.down
			all_x[4*rectangle_count+1], all_y[4*rectangle_count+1] = rectangle.right, rectangle.down
			all_x[4*rectangle_count+2], all_y[4*rectangle_count+2] = rectangle.left, rectangle.up
			all_x[4*rectangle_count+3], all_y[4*rectangle_count+3] = rectangle.right, rectangle.up
			rectangle_count += 1
		} else if kind == 1 {
			if cursor + 2 > int(length) do return -1
			x, y := input[cursor], input[cursor+1]
			cursor += 2
			if x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD do return -1
			operations[index] = {1, x, y, 0, 0, 0}
		} else do return -1
	}
	if cursor != int(length) do return -1

	corner_count := rectangle_count * 4
	x_count := sort_unique(&all_x[0], corner_count)
	y_count := sort_unique(&all_y[0], corner_count)
	var present: [((MAX_COORDS+1)*MAX_COORDS)]bool
	for i := 0; i < (MAX_COORDS+1)*MAX_COORDS; i += 1 { present[i] = false }
	for index := 0; index < n; index += 1 { register_rectangle(&all_x[0], &all_y[0], x_count, y_count, &present[0], initial[index]) }
	for index := 0; index < q; index += 1 {
		if operations[index].kind == 0 {
			op := operations[index]
			register_rectangle(&all_x[0], &all_y[0], x_count, y_count, &present[0], Rectangle{op.a, op.b, op.c, op.d, op.e})
		}
	}
	var y_values: [((MAX_COORDS+1)*MAX_COORDS)]int
	var y_counts: [MAX_COORDS+1]int
	for outer := 1; outer <= x_count; outer += 1 {
		for rank := 0; rank < y_count; rank += 1 {
			if present[outer*MAX_COORDS+rank] { y_values[outer*MAX_COORDS+y_counts[outer]] = rank; y_counts[outer] += 1 }
		}
	}
	var tree: [((MAX_COORDS+1)*(MAX_COORDS+1))]i64
	for index := 0; index < n; index += 1 { apply_rectangle(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, initial[index]) }
	var answers: [MAX_Q]i64
	answer_count := 0
	for index := 0; index < q; index += 1 {
		op := operations[index]
		if op.kind == 0 { apply_rectangle(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, Rectangle{op.a, op.b, op.c, op.d, op.e}) }
		else { answers[answer_count] = prefix_sum(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, op.a, op.b); answer_count += 1 }
	}
	output_bytes := 8 * answer_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
	for index := 0; index < answer_count; index += 1 { store_i64_le(output, index*8, answers[index]) }
	return i64(output_bytes)
}
