module kirkpatrick_seidel_convex_hull

const max_points = 32
const max_input_values = 66
const max_coordinate = i64(1000)

struct Point { x i64; y i64 }
struct Slope { dy i64; dx i64 }
struct Bridge { left int; right int }

fn compare_slope(a Slope, b Slope) int {
	left := a.dy * b.dx
	right := b.dy * a.dx
	if left < right { return -1 }
	if left > right { return 1 }
	return 0
}

fn select_id_by_x(mut ids []int, rank int, points []Point) int {
	if ids.len <= 5 {
		for i in 1 .. ids.len {
			value := ids[i]
			mut j := i
			for j > 0 && points[ids[j - 1]].x > points[value].x {
				ids[j] = ids[j - 1]
				j--
			}
			ids[j] = value
		}
		return ids[rank]
	}
	mut medians := []int{cap: ids.len}
	mut start := 0
	for start < ids.len {
		end := if start + 5 < ids.len { start + 5 } else { ids.len }
		mut group := ids[start..end].clone()
		medians << select_id_by_x(mut group, (group.len - 1) / 2, points)
		start = end
	}
	mut median_values := medians.clone()
	pivot := select_id_by_x(mut median_values, (median_values.len - 1) / 2, points)
	mut lower := []int{cap: ids.len}
	mut equal := []int{cap: ids.len}
	mut upper := []int{cap: ids.len}
	for id in ids {
		if points[id].x < points[pivot].x { lower << id }
		else if points[id].x > points[pivot].x { upper << id }
		else { equal << id }
	}
	if rank < lower.len { return select_id_by_x(mut lower, rank, points) }
	if rank < lower.len + equal.len { return pivot }
	return select_id_by_x(mut upper, rank - lower.len - equal.len, points)
}

fn sort_slopes(mut values []Slope) {
	for i in 1 .. values.len {
		value := values[i]
		mut j := i
		for j > 0 && compare_slope(values[j - 1], value) > 0 {
			values[j] = values[j - 1]
			j--
		}
		values[j] = value
	}
}

fn select_slope(mut values []Slope, rank int) Slope {
	if values.len <= 5 {
		sort_slopes(mut values)
		return values[rank]
	}
	mut medians := []Slope{cap: values.len}
	mut start := 0
	for start < values.len {
		end := if start + 5 < values.len { start + 5 } else { values.len }
		mut group := values[start..end].clone()
		sort_slopes(mut group)
		medians << group[(group.len - 1) / 2]
		start = end
	}
	mut median_values := medians.clone()
	pivot := select_slope(mut median_values, (median_values.len - 1) / 2)
	mut lower := []Slope{cap: values.len}
	mut equal := []Slope{cap: values.len}
	mut upper := []Slope{cap: values.len}
	for value in values {
		order := compare_slope(value, pivot)
		if order < 0 { lower << value }
		else if order > 0 { upper << value }
		else { equal << value }
	}
	if rank < lower.len { return select_slope(mut lower, rank) }
	if rank < lower.len + equal.len { return pivot }
	return select_slope(mut upper, rank - lower.len - equal.len)
}

fn pair_slope(first int, second int, points []Point) Slope {
	left, right := first, second
	if points[left].x > points[right].x { left, right = right, left }
	return Slope{ dy: points[right].y - points[left].y, dx: points[right].x - points[left].x }
}

fn upper_bridge(points []Point, mut candidates []int, separator i64) Bridge {
	for candidates.len > 2 {
		mut slopes := []Slope{cap: candidates.len / 2}
		for pair := 0; pair < candidates.len / 2; pair++ {
			slopes << pair_slope(candidates[2 * pair], candidates[2 * pair + 1], points)
		}
		mut slope_values := slopes.clone()
		median := select_slope(mut slope_values, (slope_values.len - 1) / 2)
		mut support := i64(-5000000)
		for id in candidates {
			p := points[id]
			score := p.y * median.dx - median.dy * p.x
			if score > support { support = score }
		}
		mut left := -1
		mut right := -1
		for id in candidates {
			p := points[id]
			if p.y * median.dx - median.dy * p.x == support {
				if left < 0 || p.x < points[left].x { left = id }
				if right < 0 || p.x > points[right].x { right = id }
			}
		}
		if points[left].x <= separator && separator < points[right].x {
			return Bridge{ left: left, right: right }
		}
		support_is_left := points[right].x <= separator
		mut retained := []int{cap: candidates.len}
		for pair := 0; pair < candidates.len / 2; pair++ {
			first, second := candidates[2 * pair], candidates[2 * pair + 1]
			order := compare_slope(pair_slope(first, second, points), median)
			if support_is_left {
				if order < 0 { retained << first; retained << second }
				else {
					chosen := if points[first].x > points[second].x { first } else { second }
					retained << chosen
				}
			} else if order > 0 {
				retained << first; retained << second
			} else {
			chosen := if points[first].x < points[second].x { first } else { second }
			retained << chosen
			}
		}
		if candidates.len % 2 == 1 { retained << candidates[candidates.len - 1] }
		candidates = retained
	}
	if points[candidates[0]].x < points[candidates[1]].x {
		return Bridge{ left: candidates[0], right: candidates[1] }
	}
	return Bridge{ left: candidates[1], right: candidates[0] }
}

fn append_unique(mut chain []int, point int) {
	if chain.len == 0 || chain[chain.len - 1] != point { chain << point }
}

fn connect_upper(points []Point, candidates []int, left int, right int, mut chain []int) {
	if left == right { append_unique(mut chain, left); return }
	mut median_ids := candidates.clone()
	separator := points[select_id_by_x(mut median_ids, (median_ids.len - 1) / 2, points)].x
	mut bridge_candidates := candidates.clone()
	bridge := upper_bridge(points, mut bridge_candidates, separator)
	mut left_set := []int{cap: candidates.len}
	mut right_set := []int{cap: candidates.len}
	for id in candidates {
		if points[id].x <= points[bridge.left].x { left_set << id }
		if points[id].x >= points[bridge.right].x { right_set << id }
	}
	connect_upper(points, left_set, left, bridge.left, mut chain)
	append_unique(mut chain, bridge.right)
	connect_upper(points, right_set, bridge.right, right, mut chain)
}

fn store_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'kirkpatrick_seidel_convex_hull']
pub fn kirkpatrick_seidel_convex_hull(values &i64, length usize,
		output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_input_values) { return -1 }
		if values[0] < 3 || values[0] > max_points { return -1 }
		count := int(values[0])
		if length != usize(1 + 2 * count) { return -1 }
		mut original := []Point{len: count}
		mut upper_points := []Point{len: count}
		mut lower_points := []Point{len: count}
		mut seen_x := [2001]bool{}
		for index in 0 .. count {
			x, y := values[1 + 2 * index], values[2 + 2 * index]
			if x < -max_coordinate || x > max_coordinate || y < -max_coordinate || y > max_coordinate { return -1 }
			slot := int(x + max_coordinate)
			if seen_x[slot] { return -1 }
			seen_x[slot] = true
			original[index] = Point{ x: x, y: y }
			upper_points[index] = Point{ x: x, y: y }
			lower_points[index] = Point{ x: x, y: -y }
		}
		mut non_collinear := false
		for index in 2 .. count {
			cross := (original[1].x - original[0].x) * (original[index].y - original[0].y) -
				(original[1].y - original[0].y) * (original[index].x - original[0].x)
			if cross != 0 { non_collinear = true; break }
		}
		if !non_collinear { return -1 }
		mut ids := []int{len: count}
		mut left_index := 0
		mut right_index := 0
		for index in 0 .. count {
			ids[index] = index
			if original[index].x < original[left_index].x { left_index = index }
			if original[index].x > original[right_index].x { right_index = index }
		}
		mut upper := []int{cap: count}
		mut lower := []int{cap: count}
		connect_upper(upper_points, ids, left_index, right_index, mut upper)
		connect_upper(lower_points, ids, left_index, right_index, mut lower)
		mut hull := lower.clone()
		if upper.len > 2 {
			for index := upper.len - 2; index > 0; index-- { append_unique(mut hull, upper[index]) }
		}
		byte_count := hull.len * 16
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for index, point_id in hull {
			store_i64_le(output, 16 * index, original[point_id].x)
			store_i64_le(output, 16 * index + 8, original[point_id].y)
		}
		return i64(byte_count)
	}
}
