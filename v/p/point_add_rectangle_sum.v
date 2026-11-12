module point_add_rectangle_sum

const max_n = 32
const max_q = 32
const max_points = max_n + max_q
const max_parseable_input = usize(2 + 3 * max_n + 5 * max_q + 1)
const max_coord = i64(1_000_000)
const max_weight = i64(1_000_000)

struct Point { x i64; y i64; weight i64 }
struct Operation { kind i64; a i64; b i64; c i64; d i64 }

fn lowbit(value int) int { return value & -value }

fn lower_bound_i64(values &i64, count int, target i64) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right - left) / 2
			if values[middle] < target { left = middle + 1 } else { right = middle }
		}
		return left
	}
}

fn lower_bound_int(values &int, count int, target int) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right - left) / 2
			if values[middle] < target { left = middle + 1 } else { right = middle }
		}
		return left
	}
}

fn sort_unique(mut values &i64, count int) int {
	unsafe {
		for index in 1 .. count {
			value := values[index]
			mut position := index
			for position > 0 && values[position - 1] > value {
				values[position] = values[position - 1]
				position--
			}
			values[position] = value
		}
		mut unique_count := 0
		for index in 0 .. count {
			if unique_count == 0 || values[index] != values[unique_count - 1] {
				values[unique_count] = values[index]
				unique_count++
			}
		}
		return unique_count
	}
}

fn register_coordinate(xs &i64, ys &i64, x_count int, y_count int,
	mut present &bool, x i64, y i64) {
	unsafe {
		mut outer := lower_bound_i64(xs, x_count, x) + 1
		rank := lower_bound_i64(ys, y_count, y)
		for outer <= x_count {
			present[outer * max_points + rank] = true
			outer += lowbit(outer)
		}
	}
}

fn fenwick_add(mut tree &i64, y_values &int, y_counts &int, x_count int,
	xs &i64, ys &i64, y_count int, x i64, y i64, weight i64) {
	unsafe {
		mut outer := lower_bound_i64(xs, x_count, x) + 1
		y_rank := lower_bound_i64(ys, y_count, y)
		for outer <= x_count {
			row := outer * max_points
			mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_rank) + 1
			for inner <= y_counts[outer] {
				tree[outer * (max_points + 1) + inner] += weight
				inner += lowbit(inner)
			}
			outer += lowbit(outer)
		}
	}
}

fn prefix_sum(tree &i64, y_values &int, y_counts &int, x_count int,
	xs &i64, ys &i64, y_count int, x_limit i64, y_limit i64) i64 {
	unsafe {
		mut outer := lower_bound_i64(xs, x_count, x_limit)
		y_limit_rank := lower_bound_i64(ys, y_count, y_limit)
		mut total := i64(0)
		for outer > 0 {
			row := outer * max_points
			mut inner := lower_bound_int(&y_values[row], y_counts[outer], y_limit_rank)
			for inner > 0 {
				total += tree[outer * (max_points + 1) + inner]
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
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'point_add_rectangle_sum']
pub fn point_add_rectangle_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		mut initial := [max_n]Point{}
		mut operations := [max_q]Operation{}
		mut all_x := [max_points]i64{}
		mut all_y := [max_points]i64{}
		mut point_count, cursor := 0, 2
		for index in 0 .. n {
			if cursor + 3 > int(length) { return -1 }
			x, y, weight := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if x < 0 || x > max_coord || y < 0 || y > max_coord || weight < 0 || weight > max_weight { return -1 }
			initial[index] = Point{x: x, y: y, weight: weight}
			all_x[point_count], all_y[point_count] = x, y
			point_count++
		}
		mut query_count := 0
		for index in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 {
				if cursor + 3 > int(length) { return -1 }
				x, y, weight := input[cursor], input[cursor + 1], input[cursor + 2]
				cursor += 3
				if x < 0 || x > max_coord || y < 0 || y > max_coord || weight < 0 || weight > max_weight { return -1 }
				operations[index] = Operation{kind: 0, a: x, b: y, c: weight}
				all_x[point_count], all_y[point_count] = x, y
				point_count++
			} else if kind == 1 {
				if cursor + 4 > int(length) { return -1 }
				left, down, right, up := input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]
				cursor += 4
				if left < 0 || left >= right || right > max_coord || down < 0 || down >= up || up > max_coord { return -1 }
				operations[index] = Operation{kind: 1, a: left, b: down, c: right, d: up}
				query_count++
			} else { return -1 }
		}
		if cursor != int(length) { return -1 }

		x_count := sort_unique(&all_x[0], point_count)
		y_count := sort_unique(&all_y[0], point_count)
		mut present := [((max_points + 1) * max_points)]bool{}
		for index in 0 .. n { register_coordinate(&all_x[0], &all_y[0], x_count, y_count, &present[0], initial[index].x, initial[index].y) }
		for index in 0 .. q {
			if operations[index].kind == 0 { register_coordinate(&all_x[0], &all_y[0], x_count, y_count, &present[0], operations[index].a, operations[index].b) }
		}
		mut y_values := [((max_points + 1) * max_points)]int{}
		mut y_counts := [max_points + 1]int{}
		for outer in 1 .. (x_count + 1) {
			for rank in 0 .. y_count {
				if present[outer * max_points + rank] { y_values[outer * max_points + y_counts[outer]] = rank; y_counts[outer]++ }
			}
		}
		mut tree := [((max_points + 1) * (max_points + 1))]i64{}
		for index in 0 .. n { fenwick_add(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, initial[index].x, initial[index].y, initial[index].weight) }
		mut answers := [max_q]i64{}
		mut answer_count := 0
		for index in 0 .. q {
			op := operations[index]
			if op.kind == 0 { fenwick_add(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op.a, op.b, op.c) }
			else {
				answers[answer_count] = prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op.c, op.d) -
					prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op.a, op.d) -
					prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op.c, op.b) +
					prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op.a, op.b)
				answer_count++
			}
		}
		output_bytes := 8 * answer_count
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		for index in 0 .. answer_count { store_i64_le(output, index * 8, answers[index]) }
		return i64(output_bytes)
	}
}
