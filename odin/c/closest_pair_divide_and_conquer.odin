package closest_pair_divide_and_conquer

import "core:c"

MAX_POINTS :: 1024

Point :: struct { x, y: i64 }
Pair_Result :: struct {
	valid: bool,
	distance_squared: u64,
	first, second: int,
}

before :: proc "contextless" (left, right: int, points: [^]Point, by_y: bool) -> bool {
	if by_y {
		if points[left].y != points[right].y do return points[left].y < points[right].y
		if points[left].x != points[right].x do return points[left].x < points[right].x
	} else {
		if points[left].x != points[right].x do return points[left].x < points[right].x
		if points[left].y != points[right].y do return points[left].y < points[right].y
	}
	return left < right
}

sort_indices :: proc "contextless" (indices, scratch: [^]int, begin, end: int,
		points: [^]Point, by_y: bool) {
	if end - begin < 2 do return
	middle := begin + (end - begin) / 2
	sort_indices(indices, scratch, begin, middle, points, by_y)
	sort_indices(indices, scratch, middle, end, points, by_y)
	left := begin
	right := middle
	output := begin
	for left < middle && right < end {
		if before(indices[right], indices[left], points, by_y) {
			scratch[output] = indices[right]
			right += 1
		} else {
			scratch[output] = indices[left]
			left += 1
		}
		output += 1
	}
	for left < middle {
		scratch[output] = indices[left]
		left += 1
		output += 1
	}
	for right < end {
		scratch[output] = indices[right]
		right += 1
		output += 1
	}
	for index := begin; index < end; index += 1 {
		indices[index] = scratch[index]
	}
}

squared_distance :: proc "contextless" (left, right: int, points: [^]Point) -> u64 {
	dx := points[left].x - points[right].x
	dy := points[left].y - points[right].y
	return u64(dx * dx) + u64(dy * dy)
}

choose :: proc "contextless" (left, right: Pair_Result) -> Pair_Result {
	if !left.valid do return right
	if !right.valid do return left
	if left.distance_squared < right.distance_squared do return left
	if right.distance_squared < left.distance_squared do return right
	if left.first < right.first || (left.first == right.first && left.second <= right.second) do return left
	return right
}

candidate :: proc "contextless" (left, right: int, points: [^]Point) -> Pair_Result {
	first := left
	second := right
	if first > second {
		temporary := first
		first = second
		second = temporary
	}
	return Pair_Result{valid = true, distance_squared = squared_distance(first, second, points), first = first, second = second}
}

search :: proc "contextless" (x_order: [^]int, begin, end: int,
		y_order: [^]int, y_count: int, rank: [^]int, points: [^]Point) -> Pair_Result {
	count := end - begin
	if count <= 3 {
		best := Pair_Result{valid = false}
		for i := begin; i < end; i += 1 {
			for j := i + 1; j < end; j += 1 {
				best = choose(best, candidate(x_order[i], x_order[j], points))
			}
		}
		return best
	}

	middle := begin + count / 2
	y_left: [MAX_POINTS]int
	y_right: [MAX_POINTS]int
	left_count := 0
	right_count := 0
	for i := 0; i < y_count; i += 1 {
		point := y_order[i]
		if rank[point] < middle {
			y_left[left_count] = point
			left_count += 1
		} else {
			y_right[right_count] = point
			right_count += 1
		}
	}
	best := choose(
		search(x_order, begin, middle, &y_left[0], left_count, rank, points),
		search(x_order, middle, end, &y_right[0], right_count, rank, points),
	)

	strip: [MAX_POINTS]int
	strip_count := 0
	middle_x := points[x_order[middle]].x
	for i := 0; i < y_count; i += 1 {
		point := y_order[i]
		dx := points[point].x - middle_x
		if u64(dx * dx) <= best.distance_squared {
			strip[strip_count] = point
			strip_count += 1
		}
	}
	for i := 0; i < strip_count; i += 1 {
		for j := i + 1; j < strip_count; j += 1 {
			dy := points[strip[j]].y - points[strip[i]].y
			if u64(dy * dy) > best.distance_squared do break
			best = choose(best, candidate(strip[i], strip[j], points))
		}
	}
	return best
}

write_pair :: proc "contextless" (output: [^]u8, pair: Pair_Result) {
	first := u32(pair.first)
	second := u32(pair.second)
	for byte := 0; byte < 4; byte += 1 {
		shift := u32(byte * 8)
		output[byte] = u8((first >> shift) & 0xFF)
		output[4 + byte] = u8((second >> shift) & 0xFF)
	}
}

// Deterministic closest pair with x-rank divide-and-conquer and a y-ordered strip.
@(export)
closest_pair_divide_and_conquer :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == nil) do return -1
	point_count := int(length / 2)

	points: [MAX_POINTS]Point
	x_order, y_order, rank, scratch: [MAX_POINTS]int
	for index := 0; index < point_count; index += 1 {
		x := values[2 * index]
		y := values[2 * index + 1]
		if x < -1_000_000_000 || x > 1_000_000_000 || y < -1_000_000_000 || y > 1_000_000_000 do return -1
		points[index] = Point{x = x, y = y}
		x_order[index] = index
		y_order[index] = index
	}
	if point_count < 2 do return 0
	sort_indices(&x_order[0], &scratch[0], 0, point_count, &points[0], false)
	for index := 0; index < point_count; index += 1 {
		rank[x_order[index]] = index
	}

	duplicate := Pair_Result{valid = false}
	group_begin := 0
	for group_begin < point_count {
		group_end := group_begin + 1
		anchor := x_order[group_begin]
		for group_end < point_count && points[x_order[group_end]].x == points[anchor].x &&
			points[x_order[group_end]].y == points[anchor].y {
			group_end += 1
		}
		if group_end - group_begin > 1 {
			first := MAX_POINTS
			second := MAX_POINTS
			for index := group_begin; index < group_end; index += 1 {
				id := x_order[index]
				if id < first {
					second = first
					first = id
				} else if id < second {
					second = id
				}
			}
			duplicate = choose(duplicate, Pair_Result{valid = true, distance_squared = 0, first = first, second = second})
		}
		group_begin = group_end
	}
	if duplicate.valid {
		if output == nil || output_capacity < 8 do return -2
		write_pair(output, duplicate)
		return 2
	}

	sort_indices(&y_order[0], &scratch[0], 0, point_count, &points[0], true)
	best := search(&x_order[0], 0, point_count, &y_order[0], point_count, &rank[0], &points[0])
	if !best.valid do return -1
	if output == nil || output_capacity < 8 do return -2
	write_pair(output, best)
	return 2
}
