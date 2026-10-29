module manhattan_mst

const max_points = 32
const max_input_length = 1 + 2 * max_points
const coordinate_limit = i64(1_000_000)

@[export: 'manhattan_mst']
pub fn manhattan_mst(values &i64, length usize) i64 {
	if length < 1 || length > max_input_length { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 1 || count_value > max_points { return -1 }
	count := int(count_value)
	if length != usize(1 + 2 * count) { return -1 }

	mut x := [max_points]i64{}
	mut y := [max_points]i64{}
	for point in 0 .. count {
		x[point] = unsafe { values[1 + 2 * point] }
		y[point] = unsafe { values[2 + 2 * point] }
		if x[point] < -coordinate_limit || x[point] > coordinate_limit ||
			y[point] < -coordinate_limit || y[point] > coordinate_limit { return -1 }
	}

	mut in_tree := [max_points]bool{}
	mut has_best := [max_points]bool{}
	mut best := [max_points]i64{}
	has_best[0] = true
	mut total := i64(0)
	for _ in 0 .. count {
		mut selected := count
		for point in 0 .. count {
			if !in_tree[point] && has_best[point] &&
				(selected == count || best[point] < best[selected]) { selected = point }
		}
		if selected == count { return -1 }
		in_tree[selected] = true
		total += best[selected]
		for point in 0 .. count {
			if in_tree[point] { continue }
			dx := x[selected] - x[point]
			dy := y[selected] - y[point]
			distance := (if dx < 0 { -dx } else { dx }) + (if dy < 0 { -dy } else { dy })
			if !has_best[point] || distance < best[point] {
				has_best[point] = true
				best[point] = distance
			}
		}
	}
	return total
}
