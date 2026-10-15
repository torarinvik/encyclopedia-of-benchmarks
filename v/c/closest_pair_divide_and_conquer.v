module closest_pair_divide_and_conquer

const max_points = 1024

struct Point {
	x i64
	y i64
}

struct PairResult {
	valid bool
	distance_squared u64
	first int
	second int
}

fn before(left int, right int, points []Point, by_y bool) bool {
	if by_y {
		if points[left].y != points[right].y { return points[left].y < points[right].y }
		if points[left].x != points[right].x { return points[left].x < points[right].x }
	} else {
		if points[left].x != points[right].x { return points[left].x < points[right].x }
		if points[left].y != points[right].y { return points[left].y < points[right].y }
	}
	return left < right
}

fn sort_indices(mut indices []int, mut scratch []int, begin int, end int, points []Point,
		by_y bool) {
	if end - begin < 2 { return }
	middle := begin + (end - begin) / 2
	sort_indices(mut indices, mut scratch, begin, middle, points, by_y)
	sort_indices(mut indices, mut scratch, middle, end, points, by_y)
	mut left := begin
	mut right := middle
	mut out := begin
	for left < middle && right < end {
		if before(indices[right], indices[left], points, by_y) {
			scratch[out] = indices[right]
			right++
		} else {
			scratch[out] = indices[left]
			left++
		}
		out++
	}
	for left < middle {
		scratch[out] = indices[left]
		left++
		out++
	}
	for right < end {
		scratch[out] = indices[right]
		right++
		out++
	}
	for index in begin .. end { indices[index] = scratch[index] }
}

fn squared_distance(left int, right int, points []Point) u64 {
	dx := points[left].x - points[right].x
	dy := points[left].y - points[right].y
	return u64(dx * dx) + u64(dy * dy)
}

fn choose(left PairResult, right PairResult) PairResult {
	if !left.valid { return right }
	if !right.valid { return left }
	if left.distance_squared < right.distance_squared { return left }
	if right.distance_squared < left.distance_squared { return right }
	if left.first < right.first || (left.first == right.first && left.second <= right.second) {
		return left
	}
	return right
}

fn candidate(left int, right int, points []Point) PairResult {
	first := if left < right { left } else { right }
	second := if left < right { right } else { left }
	return PairResult{
		valid: true
		distance_squared: squared_distance(first, second, points)
		first: first
		second: second
	}
}

fn search(x_order []int, begin int, end int, y_order []int, rank []int,
		points []Point) PairResult {
	count := end - begin
	if count <= 3 {
		mut best := PairResult{}
		for i in begin .. end {
			for j in i + 1 .. end {
				best = choose(best, candidate(x_order[i], x_order[j], points))
			}
		}
		return best
	}

	middle := begin + count / 2
	mut y_left := []int{cap: y_order.len}
	mut y_right := []int{cap: y_order.len}
	for point in y_order {
		if rank[point] < middle { y_left << point } else { y_right << point }
	}
	mut best := choose(search(x_order, begin, middle, y_left, rank, points),
		search(x_order, middle, end, y_right, rank, points))

	middle_x := points[x_order[middle]].x
	mut strip := []int{cap: y_order.len}
	for point in y_order {
		dx := points[point].x - middle_x
		if u64(dx * dx) <= best.distance_squared { strip << point }
	}
	for i in 0 .. strip.len {
		for j in i + 1 .. strip.len {
			dy := points[strip[j]].y - points[strip[i]].y
			if u64(dy * dy) > best.distance_squared { break }
			best = choose(best, candidate(strip[i], strip[j], points))
		}
	}
	return best
}

fn write_pair(output &u8, pair PairResult) {
	unsafe {
		first := u32(pair.first)
		second := u32(pair.second)
		for byte in 0 .. 4 {
			output[byte] = u8((first >> u32(8 * byte)) & 255)
			output[4 + byte] = u8((second >> u32(8 * byte)) & 255)
		}
	}
}

// Return the lexicographically first original-index pair at minimum distance.
@[export: 'closest_pair_divide_and_conquer']
pub fn closest_pair_divide_and_conquer(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length > 2 * max_points || length % 2 != 0 || (length != 0 && values == nil) { return -1 }
	point_count := length / 2
	mut points := []Point{len: point_count}
	mut x_order := []int{len: point_count}
	mut y_order := []int{len: point_count}
	mut rank := []int{len: point_count}
	mut scratch := []int{len: point_count}
	unsafe {
		for index in 0 .. point_count {
			x := values[2 * index]
			y := values[2 * index + 1]
			if x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000 {
				return -1
			}
			points[index] = Point{x: x, y: y}
			x_order[index] = index
			y_order[index] = index
		}
	}
	if point_count < 2 { return 0 }
	sort_indices(mut x_order, mut scratch, 0, point_count, points, false)
	for position, point in x_order { rank[point] = position }

	mut duplicate := PairResult{}
	mut begin := 0
	for begin < point_count {
		mut end := begin + 1
		anchor := x_order[begin]
		for end < point_count && points[x_order[end]].x == points[anchor].x &&
			points[x_order[end]].y == points[anchor].y { end++ }
		if end - begin > 1 {
			mut first := max_points
			mut second := max_points
			for position in begin .. end {
				id := x_order[position]
				if id < first {
					second = first
					first = id
				} else if id < second {
					second = id
				}
			}
			duplicate = choose(duplicate, PairResult{
				valid: true
				distance_squared: 0
				first: first
				second: second
			})
		}
		begin = end
	}
	if duplicate.valid {
		if output == nil || output_capacity < 8 { return -2 }
		write_pair(output, duplicate)
		return 2
	}

	sort_indices(mut y_order, mut scratch, 0, point_count, points, true)
	best := search(x_order, 0, point_count, y_order, rank, points)
	if !best.valid { return -1 }
	if output == nil || output_capacity < 8 { return -2 }
	write_pair(output, best)
	return 2
}
