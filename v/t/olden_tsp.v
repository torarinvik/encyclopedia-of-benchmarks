module main

import math

const max_cities = 7
const conquer_threshold = 3
const scale = 1000.0

fn city_distance(x [7]i64, y [7]i64, a int, b int) f64 {
	dx := f64(x[a] - x[b])
	dy := f64(y[a] - y[b])
	return math.sqrt(dx * dx + dy * dy)
}

fn subtree_size(node int, count int) int {
	if node >= count { return 0 }
	return 1 + subtree_size(2 * node + 1, count) + subtree_size(2 * node + 2, count)
}

fn collect_postorder(node int, count int, mut order [7]int, mut length int) {
	if node >= count { return }
	collect_postorder(2 * node + 1, count, mut order, mut length)
	collect_postorder(2 * node + 2, count, mut order, mut length)
	order[length] = node
	length++
}

fn reverse_cycle(start int, size int, mut next [7]int, mut prev [7]int) {
	mut current := start
	for _ in 0 .. size {
		old_next := next[current]
		old_prev := prev[current]
		next[current] = old_prev
		prev[current] = old_next
		current = old_next
	}
}

fn conquer(order [7]int, count int, x [7]i64, y [7]i64, mut next [7]int, mut prev [7]int) int {
	cycle := order[0]
	next[cycle] = cycle
	prev[cycle] = cycle
	for point_index in 1 .. count {
		point := order[point_index]
		mut min := cycle
		mut mindist := city_distance(x, y, point, cycle)
		mut tmp := next[cycle]
		for tmp != cycle {
			test := city_distance(x, y, tmp, point)
			if test < mindist { mindist = test; min = tmp }
			tmp = next[tmp]
		}
		next_city := next[min]
		prev_city := prev[min]
		min_to_next := city_distance(x, y, min, next_city)
		min_to_prev := city_distance(x, y, min, prev_city)
		point_to_next := city_distance(x, y, point, next_city)
		point_to_prev := city_distance(x, y, point, prev_city)
		if point_to_prev - min_to_prev < point_to_next - min_to_next {
			next[prev_city] = point; prev[point] = prev_city
			next[point] = min; prev[min] = point
		} else {
			prev[next_city] = point; next[point] = next_city
			next[min] = point; prev[point] = min
		}
	}
	return cycle
}

fn merge_cycles(a int, b int, point int, size_a int, size_b int, x [7]i64, y [7]i64,
	mut next [7]int, mut prev [7]int) int {
	mut min := a
	mut mindist := city_distance(x, y, point, a)
	mut tmp := next[a]
	for tmp != a {
		test := city_distance(x, y, point, tmp)
		if test < mindist { mindist = test; min = tmp }
		tmp = next[tmp]
	}
	mut next_city := next[min]
	mut prev_city := prev[min]
	min_to_next := city_distance(x, y, min, next_city)
	min_to_prev := city_distance(x, y, min, prev_city)
	point_to_next := city_distance(x, y, point, next_city)
	point_to_prev := city_distance(x, y, point, prev_city)
	mut n1 := 0; mut p1 := 0
	mut tton1 := f64(0.0); mut ttop1 := f64(0.0)
	if point_to_prev - min_to_prev < point_to_next - min_to_next {
		p1 = prev_city; n1 = min; tton1 = mindist; ttop1 = point_to_prev
	} else {
		p1 = min; n1 = next_city; ttop1 = mindist; tton1 = point_to_next
	}
	min = b
	mindist = city_distance(x, y, point, b)
	tmp = next[b]
	for tmp != b {
		test := city_distance(x, y, point, tmp)
		if test < mindist { mindist = test; min = tmp }
		tmp = next[tmp]
	}
	next_city = next[min]
	prev_city = prev[min]
	min_to_next = city_distance(x, y, min, next_city)
	min_to_prev = city_distance(x, y, min, prev_city)
	point_to_next = city_distance(x, y, point, next_city)
	point_to_prev = city_distance(x, y, point, prev_city)
	mut n2 := 0; mut p2 := 0
	mut tton2 := f64(0.0); mut ttop2 := f64(0.0)
	if point_to_prev - min_to_prev < point_to_next - min_to_next {
		p2 = prev_city; n2 = min; tton2 = mindist; ttop2 = point_to_prev
	} else {
		p2 = min; n2 = next_city; ttop2 = mindist; tton2 = point_to_next
	}
	n1_to_n2 := city_distance(x, y, n1, n2)
	n1_to_p2 := city_distance(x, y, n1, p2)
	p1_to_n2 := city_distance(x, y, p1, n2)
	p1_to_p2 := city_distance(x, y, p1, p2)
	mut best := ttop1 + ttop2 + n1_to_n2
	mut choice := 1
	mut test := ttop1 + tton2 + n1_to_p2
	if test < best { choice = 2; best = test }
	test = tton1 + ttop2 + p1_to_n2
	if test < best { choice = 3; best = test }
	test = tton1 + tton2 + p1_to_p2
	if test < best { choice = 4 }
	if choice == 1 {
		reverse_cycle(n2, size_b, mut next, mut prev)
		next[p1] = point; prev[point] = p1; next[point] = p2; prev[p2] = point
		next[n2] = n1; prev[n1] = n2
	} else if choice == 2 {
		next[p1] = point; prev[point] = p1; next[point] = n2; prev[n2] = point
		next[p2] = n1; prev[n1] = p2
	} else if choice == 3 {
		next[p2] = point; prev[point] = p2; next[point] = n1; prev[n1] = point
		next[p1] = n2; prev[n2] = p1
	} else {
		reverse_cycle(n1, size_a, mut next, mut prev)
		next[n1] = point; prev[point] = n1; next[point] = n2; prev[n2] = point
		next[p2] = p1; prev[p1] = p2
	}
	return point
}

fn solve_subtree(node int, count int, x [7]i64, y [7]i64, mut next [7]int, mut prev [7]int) int {
	size := subtree_size(node, count)
	if size <= conquer_threshold {
		mut order := [7]int{}
		mut order_count := 0
		collect_postorder(node, count, mut order, mut order_count)
		return conquer(order, order_count, x, y, mut next, mut prev)
	}
	left := 2 * node + 1
	right := 2 * node + 2
	left_cycle := solve_subtree(left, count, x, y, mut next, mut prev)
	right_cycle := solve_subtree(right, count, x, y, mut next, mut prev)
	return merge_cycles(left_cycle, right_cycle, node, subtree_size(left, count), subtree_size(right, count), x, y, mut next, mut prev)
}

@[export: 'olden_tsp']
pub fn olden_tsp(input &i64, length usize) i64 {
	if unsafe { input == nil } || (length != 7 && length != 15) { return -1 }
	count_value := unsafe { input[0] }
	if count_value != 3 && count_value != 7 { return -1 }
	count := int(count_value)
	if length != usize(1 + 2 * count) { return -1 }
	mut x := [7]i64{}
	mut y := [7]i64{}
	mut next := [7]int{}
	mut prev := [7]int{}
	for city in 0 .. count {
		x[city] = unsafe { input[1 + 2 * city] }
		y[city] = unsafe { input[2 + 2 * city] }
		if x[city] < -8 || x[city] > 8 || y[city] < -8 || y[city] > 8 { return -1 }
	}
	_ = solve_subtree(0, count, x, y, mut next, mut prev)
	mut tour_length := f64(0.0)
	mut city := 0
	for _ in 0 .. count {
		following := next[city]
		tour_length += city_distance(x, y, city, following)
		city = following
	}
	return i64(math.floor(tour_length * scale + 0.5))
}
