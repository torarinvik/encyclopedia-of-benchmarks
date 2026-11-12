module rectangle_add_point_get

const max_n = 32
const max_q = 32
const max_rectangles = max_n + max_q
const max_coords = 2 * max_rectangles
const max_corners = 4 * max_rectangles
const max_parseable_input = usize(2 + 5 * max_n + 6 * max_q + 1)
const max_coord = i64(1_000_000)
const max_weight = i64(1_000_000)

struct Rectangle { left i64; down i64; right i64; up i64; weight i64 }
struct Operation { kind i64; a i64; b i64; c i64; d i64; e i64 }

fn lowbit(value int) int { return value & -value }

fn lower_bound_i64(values &i64, count int, target i64) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right-left)/2
			if values[middle] < target { left = middle+1 } else { right = middle }
		}
		return left
	}
}

fn upper_bound_i64(values &i64, count int, target i64) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right-left)/2
			if values[middle] <= target { left = middle+1 } else { right = middle }
		}
		return left
	}
}

fn lower_bound_int(values &int, count int, target int) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right-left)/2
			if values[middle] < target { left = middle+1 } else { right = middle }
		}
		return left
	}
}

fn sort_unique(mut values &i64, count int) int {
	unsafe {
		for index in 1 .. count {
			value := values[index]
			mut position := index
			for position > 0 && values[position-1] > value {
				values[position] = values[position-1]
				position--
			}
			values[position] = value
		}
		mut unique_count := 0
		for index in 0 .. count {
			if unique_count == 0 || values[index] != values[unique_count-1] {
				values[unique_count] = values[index]
				unique_count++
			}
		}
		return unique_count
	}
}

fn register_event(xs &i64, x_count int, ys &i64, y_count int,
		mut present &bool, x i64, y i64) {
	unsafe {
		mut outer := lower_bound_i64(xs, x_count, x) + 1
		rank := lower_bound_i64(ys, y_count, y)
		for outer <= x_count {
			present[outer*max_coords+rank] = true
			outer += lowbit(outer)
		}
	}
}

fn register_rectangle(xs &i64, x_count int, ys &i64, y_count int,
		mut present &bool, rectangle Rectangle) {
	register_event(xs, x_count, ys, y_count, mut present, rectangle.left, rectangle.down)
	register_event(xs, x_count, ys, y_count, mut present, rectangle.right, rectangle.down)
	register_event(xs, x_count, ys, y_count, mut present, rectangle.left, rectangle.up)
	register_event(xs, x_count, ys, y_count, mut present, rectangle.right, rectangle.up)
}

fn fenwick_add(mut tree &i64, y_values &int, y_counts &int,
		xs &i64, x_count int, ys &i64, y_count int,
		x i64, y i64, weight i64) {
	unsafe {
		mut outer := lower_bound_i64(xs, x_count, x) + 1
		y_rank := lower_bound_i64(ys, y_count, y)
		for outer <= x_count {
			row := outer * max_coords
			mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_rank) + 1
			for inner <= y_counts[outer] {
				tree[outer*(max_coords+1)+inner] += weight
				inner += lowbit(inner)
			}
			outer += lowbit(outer)
		}
	}
}

fn apply_rectangle(mut tree &i64, y_values &int, y_counts &int,
		xs &i64, x_count int, ys &i64, y_count int, rectangle Rectangle) {
	fenwick_add(mut tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.left, rectangle.down, rectangle.weight)
	fenwick_add(mut tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.right, rectangle.down, -rectangle.weight)
	fenwick_add(mut tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.left, rectangle.up, -rectangle.weight)
	fenwick_add(mut tree, y_values, y_counts, xs, x_count, ys, y_count,
		rectangle.right, rectangle.up, rectangle.weight)
}

fn prefix_sum(tree &i64, y_values &int, y_counts &int,
		xs &i64, x_count int, ys &i64, y_count int, x_limit i64, y_limit i64) i64 {
	unsafe {
		mut outer := upper_bound_i64(xs, x_count, x_limit)
		y_limit_rank := upper_bound_i64(ys, y_count, y_limit)
		mut total := i64(0)
		for outer > 0 {
			row := outer * max_coords
			mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_limit_rank)
			for inner > 0 {
				total += tree[outer*(max_coords+1)+inner]
				inner -= lowbit(inner)
			}
			outer -= lowbit(outer)
		}
		return total
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'rectangle_add_point_get']
pub fn rectangle_add_point_get(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		mut initial := [max_n]Rectangle{}
		mut operations := [max_q]Operation{}
		mut all_x := [max_corners]i64{}
		mut all_y := [max_corners]i64{}
		mut rectangle_count, cursor := 0, 2
		for index in 0 .. n {
			if cursor + 5 > int(length) { return -1 }
			rectangle := Rectangle{input[cursor], input[cursor+1], input[cursor+2], input[cursor+3], input[cursor+4]}
			cursor += 5
			if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > max_coord ||
				rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > max_coord ||
				rectangle.weight < 0 || rectangle.weight > max_weight { return -1 }
			initial[index] = rectangle
			all_x[4*rectangle_count], all_y[4*rectangle_count] = rectangle.left, rectangle.down
			all_x[4*rectangle_count+1], all_y[4*rectangle_count+1] = rectangle.right, rectangle.down
			all_x[4*rectangle_count+2], all_y[4*rectangle_count+2] = rectangle.left, rectangle.up
			all_x[4*rectangle_count+3], all_y[4*rectangle_count+3] = rectangle.right, rectangle.up
			rectangle_count++
		}
		for index in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 {
				if cursor + 5 > int(length) { return -1 }
				rectangle := Rectangle{input[cursor], input[cursor+1], input[cursor+2], input[cursor+3], input[cursor+4]}
				cursor += 5
				if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > max_coord ||
					rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > max_coord ||
					rectangle.weight < 0 || rectangle.weight > max_weight { return -1 }
				operations[index] = Operation{0, rectangle.left, rectangle.down, rectangle.right, rectangle.up, rectangle.weight}
				all_x[4*rectangle_count], all_y[4*rectangle_count] = rectangle.left, rectangle.down
				all_x[4*rectangle_count+1], all_y[4*rectangle_count+1] = rectangle.right, rectangle.down
				all_x[4*rectangle_count+2], all_y[4*rectangle_count+2] = rectangle.left, rectangle.up
				all_x[4*rectangle_count+3], all_y[4*rectangle_count+3] = rectangle.right, rectangle.up
				rectangle_count++
			} else if kind == 1 {
				if cursor + 2 > int(length) { return -1 }
				x, y := input[cursor], input[cursor+1]
				cursor += 2
				if x < 0 || x > max_coord || y < 0 || y > max_coord { return -1 }
				operations[index] = Operation{1, x, y, 0, 0, 0}
			} else { return -1 }
		}
		if cursor != int(length) { return -1 }

		corner_count := rectangle_count * 4
		x_count := sort_unique(&all_x[0], corner_count)
		y_count := sort_unique(&all_y[0], corner_count)
		mut present := [((max_coords+1)*max_coords)]bool{}
		for index in 0 .. (max_coords+1)*max_coords { present[index] = false }
		for index in 0 .. n { register_rectangle(&all_x[0], x_count, &all_y[0], y_count, &present[0], initial[index]) }
		for index in 0 .. q {
			if operations[index].kind == 0 {
				op := operations[index]
				register_rectangle(&all_x[0], x_count, &all_y[0], y_count, &present[0], Rectangle{op.a, op.b, op.c, op.d, op.e})
			}
		}
		mut y_values := [((max_coords+1)*max_coords)]int{}
		mut y_counts := [(max_coords+1)]int{}
		for outer in 1 .. x_count+1 {
			for rank in 0 .. y_count {
				if present[outer*max_coords+rank] { y_values[outer*max_coords+y_counts[outer]] = rank; y_counts[outer]++ }
			}
		}
		mut tree := [((max_coords+1)*(max_coords+1))]i64{}
		for index in 0 .. n { apply_rectangle(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, initial[index]) }
		mut answers := [max_q]i64{}
		mut answer_count := 0
		for index in 0 .. q {
			op := operations[index]
			if op.kind == 0 { apply_rectangle(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, op) }
			else { answers[answer_count] = prefix_sum(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count, &all_y[0], y_count, op.a, op.b); answer_count++ }
		}
		output_bytes := 8 * answer_count
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		for index in 0 .. answer_count { store_i64_le(output, index*8, answers[index]) }
		return i64(output_bytes)
	}
}
