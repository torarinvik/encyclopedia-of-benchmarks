package kirkpatrick_seidel_convex_hull

import "core:c"

MAX_POINTS :: 32
MAX_INPUT_VALUES :: 66
MAX_COORDINATE :: i64(1000)

Point :: struct { x, y: i64 }
Slope :: struct { dy, dx: i64 }

compare_slope :: proc "contextless" (a, b: Slope) -> int {
	left := a.dy * b.dx
	right := b.dy * a.dx
	if left < right do return -1
	if left > right do return 1
	return 0
}

sort_ids_by_x :: proc "contextless" (ids: []int, points: []Point) {
	for i := 1; i < len(ids); i += 1 {
		value := ids[i]
		j := i
		for j > 0 && points[ids[j-1]].x > points[value].x {
			ids[j] = ids[j-1]
			j -= 1
		}
		ids[j] = value
	}
}

select_id_by_x :: proc "contextless" (ids: []int, rank: int, points: []Point) -> int {
	if len(ids) <= 5 {
		sort_ids_by_x(ids, points)
		return ids[rank]
	}
	medians: [MAX_POINTS]int
	median_count := 0
	start := 0
	for start < len(ids) {
		group := min(5, len(ids)-start)
		sort_ids_by_x(ids[start:start+group], points)
		medians[median_count] = ids[start+(group-1)/2]
		median_count += 1
		start += group
	}
	pivot := select_id_by_x(medians[:median_count], (median_count-1)/2, points)
	lower, cursor, upper := 0, 0, len(ids)
	for cursor < upper {
		if points[ids[cursor]].x < points[pivot].x {
			ids[lower], ids[cursor] = ids[cursor], ids[lower]
			lower += 1
			cursor += 1
		} else if points[ids[cursor]].x > points[pivot].x {
			upper -= 1
			ids[upper], ids[cursor] = ids[cursor], ids[upper]
		} else {
			cursor += 1
		}
	}
	if rank < lower do return select_id_by_x(ids[:lower], rank, points)
	if rank < upper do return pivot
	return select_id_by_x(ids[upper:], rank-upper, points)
}

sort_slopes :: proc "contextless" (values: []Slope) {
	for i := 1; i < len(values); i += 1 {
		value := values[i]
		j := i
		for j > 0 && compare_slope(values[j-1], value) > 0 {
			values[j] = values[j-1]
			j -= 1
		}
		values[j] = value
	}
}

select_slope :: proc "contextless" (values: []Slope, rank: int) -> Slope {
	if len(values) <= 5 {
		sort_slopes(values)
		return values[rank]
	}
	medians: [MAX_POINTS]Slope
	median_count := 0
	start := 0
	for start < len(values) {
		group := min(5, len(values)-start)
		sort_slopes(values[start:start+group])
		medians[median_count] = values[start+(group-1)/2]
		median_count += 1
		start += group
	}
	pivot := select_slope(medians[:median_count], (median_count-1)/2)
	lower, cursor, upper := 0, 0, len(values)
	for cursor < upper {
		order := compare_slope(values[cursor], pivot)
		if order < 0 {
			values[lower], values[cursor] = values[cursor], values[lower]
			lower += 1
			cursor += 1
		} else if order > 0 {
			upper -= 1
			values[upper], values[cursor] = values[cursor], values[upper]
		} else {
			cursor += 1
		}
	}
	if rank < lower do return select_slope(values[:lower], rank)
	if rank < upper do return pivot
	return select_slope(values[upper:], rank-upper)
}

pair_slope :: proc "contextless" (first, second: int, points: []Point) -> Slope {
	left, right := first, second
	if points[left].x > points[right].x { left, right = right, left }
	return Slope{points[right].y-points[left].y, points[right].x-points[left].x}
}

upper_bridge :: proc "contextless" (points: []Point, candidates: []int,
		separator: i64) -> (int, int) {
	count := len(candidates)
	for count > 2 {
		pair_count := count / 2
		slopes: [MAX_POINTS]Slope
		for pair in 0..<pair_count {
			slopes[pair] = pair_slope(candidates[2*pair], candidates[2*pair+1], points)
		}
		median := select_slope(slopes[:pair_count], (pair_count-1)/2)
		maximum: i64 = -5_000_000
		for i in 0..<count {
			p := points[candidates[i]]
			score := p.y*median.dx-median.dy*p.x
			if score > maximum do maximum = score
		}
		left, right := -1, -1
		for i in 0..<count {
			id := candidates[i]
			p := points[id]
			if p.y*median.dx-median.dy*p.x == maximum {
				if left < 0 || p.x < points[left].x do left = id
				if right < 0 || p.x > points[right].x do right = id
			}
		}
		if points[left].x <= separator && separator < points[right].x do return left, right
		support_is_left := points[right].x <= separator
		next: [MAX_POINTS]int
		next_count := 0
		for pair in 0..<pair_count {
			first, second := candidates[2*pair], candidates[2*pair+1]
			order := compare_slope(pair_slope(first, second, points), median)
			keep_first, keep_second := false, false
			if support_is_left {
				keep_first, keep_second = order < 0, order < 0
				if order >= 0 {
					keep_first = points[first].x > points[second].x
					keep_second = points[second].x > points[first].x
				}
			} else {
				keep_first, keep_second = order > 0, order > 0
				if order <= 0 {
					keep_first = points[first].x < points[second].x
					keep_second = points[second].x < points[first].x
				}
			}
			if keep_first { next[next_count] = first; next_count += 1 }
			if keep_second { next[next_count] = second; next_count += 1 }
		}
		if count % 2 != 0 { next[next_count] = candidates[count-1]; next_count += 1 }
		for i in 0..<next_count { candidates[i] = next[i] }
		count = next_count
	}
	if points[candidates[0]].x < points[candidates[1]].x do return candidates[0], candidates[1]
	return candidates[1], candidates[0]
}

append_unique :: proc "contextless" (chain: []int, chain_count: ^int, point: int) {
	if chain_count^ == 0 || chain[chain_count^-1] != point {
		chain[chain_count^] = point
		chain_count^ += 1
	}
}

connect_upper :: proc "contextless" (points: []Point, candidates: []int,
		left, right: int, chain: []int, chain_count: ^int) {
	if left == right { append_unique(chain, chain_count, left); return }
	median_ids: [MAX_POINTS]int
	mutable_candidates: [MAX_POINTS]int
	for i in 0..<len(candidates) {
		median_ids[i] = candidates[i]
		mutable_candidates[i] = candidates[i]
	}
	separator_id := select_id_by_x(median_ids[:len(candidates)], (len(candidates)-1)/2, points)
	separator := points[separator_id].x
	bridge_left, bridge_right := upper_bridge(points, mutable_candidates[:len(candidates)], separator)
	left_set: [MAX_POINTS]int
	right_set: [MAX_POINTS]int
	left_count, right_count := 0, 0
	for id in candidates {
		if points[id].x <= points[bridge_left].x { left_set[left_count] = id; left_count += 1 }
		if points[id].x >= points[bridge_right].x { right_set[right_count] = id; right_count += 1 }
	}
	connect_upper(points, left_set[:left_count], left, bridge_left, chain, chain_count)
	append_unique(chain, chain_count, bridge_right)
	connect_upper(points, right_set[:right_count], bridge_right, right, chain, chain_count)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(byte*8)) }
}

@(export)
kirkpatrick_seidel_convex_hull :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	if values[0] < 3 || values[0] > MAX_POINTS do return -1
	count := int(values[0])
	if length != c.size_t(1+2*count) do return -1
	original: [MAX_POINTS]Point
	upper_points: [MAX_POINTS]Point
	lower_points: [MAX_POINTS]Point
	seen_x: [2001]bool = {}
	for i in 0..<count {
		x, y := values[1+2*i], values[2+2*i]
		if x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE do return -1
		slot := int(x+MAX_COORDINATE)
		if seen_x[slot] do return -1
		seen_x[slot] = true
		original[i] = Point{x,y}; upper_points[i] = Point{x,y}; lower_points[i] = Point{x,-y}
	}
	non_collinear := false
	for i in 2..<count {
		cross := (original[1].x-original[0].x)*(original[i].y-original[0].y)-
			(original[1].y-original[0].y)*(original[i].x-original[0].x)
		if cross != 0 { non_collinear = true; break }
	}
	if !non_collinear do return -1
	ids: [MAX_POINTS]int
	upper: [MAX_POINTS]int
	lower: [MAX_POINTS]int
	hull: [MAX_POINTS]int
	left_index, right_index := 0, 0
	for i in 0..<count {
		ids[i] = i
		if original[i].x < original[left_index].x do left_index = i
		if original[i].x > original[right_index].x do right_index = i
	}
	upper_count, lower_count := 0, 0
	connect_upper(upper_points[:count], ids[:count], left_index, right_index, upper[:], &upper_count)
	connect_upper(lower_points[:count], ids[:count], left_index, right_index, lower[:], &lower_count)
	hull_count := 0
	for i in 0..<lower_count { append_unique(hull[:], &hull_count, lower[i]) }
	for i := upper_count-1; i > 1; i -= 1 { append_unique(hull[:], &hull_count, upper[i-1]) }
	byte_count := hull_count*16
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for i in 0..<hull_count {
		p := original[hull[i]]
		store_i64_le(output, 16*i, p.x)
		store_i64_le(output, 16*i+8, p.y)
	}
	return i64(byte_count)
}
