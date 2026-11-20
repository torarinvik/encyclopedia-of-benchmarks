package manhattan_mst_candidate_edge_reduction

import "core:c"
import "core:sort"

MAX_N :: 31
MAX_INPUT_LENGTH :: 1 + 2 * MAX_N
MAX_CANDIDATE_EDGES :: 4 * MAX_N
COORDINATE_BITSET_WORDS :: 32
COORDINATE_LIMIT :: i64(1_000)

Point :: struct { x, y: i64 }
Edge :: struct { weight: i64, u, v: int }
Point_Order :: struct { primary, secondary: i64, id: int }

mark_coordinate :: proc "contextless" (seen: [^]u64, coordinate: i64) -> bool {
	index := int(coordinate + COORDINATE_LIMIT)
	word := index / 64
	mask := u64(1) << (index % 64)
	if seen[word] & mask != 0 do return false
	seen[word] |= mask
	return true
}

compare_point_order :: proc "contextless" (left, right: Point_Order) -> int {
	if left.primary < right.primary do return -1
	if left.primary > right.primary do return 1
	if left.secondary < right.secondary do return -1
	if left.secondary > right.secondary do return 1
	if left.id < right.id do return -1
	if left.id > right.id do return 1
	return 0
}

compare_edge_order :: proc "contextless" (left, right: Edge) -> int {
	if left.weight < right.weight do return -1
	if left.weight > right.weight do return 1
	if left.u < right.u do return -1
	if left.u > right.u do return 1
	if left.v < right.v do return -1
	if left.v > right.v do return 1
	return 0
}

fenwick_add :: proc "contextless" (tree: [^]int, index_input, delta, count: int) {
	mut index := index_input
	for index <= count {
		tree[index] += delta
		index += index & -index
	}
}

fenwick_prefix :: proc "contextless" (tree: [^]int, index_input: int) -> int {
	mut index := index_input
	mut total := 0
	for index > 0 {
		total += tree[index]
		index &= index - 1
	}
	return total
}

fenwick_find_by_order :: proc "contextless" (tree: [^]int, count, order: int) -> int {
	mut step := 1
	for step * 2 <= count { step *= 2 }
	mut index := 0
	mut remaining := order
	for step > 0 {
		next := index + step
		if next <= count && tree[next] < remaining {
			index = next
			remaining -= tree[next]
		}
		step /= 2
	}
	return index
}

find_root :: proc "contextless" (parent: [^]int, node_input: int) -> int {
	mut node := node_input
	mut root := node
	for parent[root] != root { root = parent[root] }
	for parent[node] != node {
		next := parent[node]
		parent[node] = root
		node = next
	}
	return root
}

@(export)
manhattan_mst_candidate_edge_reduction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_word := input[0]
	if n_word < 0 || n_word > MAX_N do return -1
	n := int(n_word)
	if int(length) != 1 + 2*n do return -1

	points: [MAX_N]Point
	mut seen_x: [COORDINATE_BITSET_WORDS]u64
	mut seen_y: [COORDINATE_BITSET_WORDS]u64
	for word := 0; word < COORDINATE_BITSET_WORDS; word += 1 {
		seen_x[word] = 0
		seen_y[word] = 0
	}
	for point := 0; point < n; point += 1 {
		x, y := input[1+2*point], input[2+2*point]
		if x < -COORDINATE_LIMIT || x > COORDINATE_LIMIT || y < -COORDINATE_LIMIT || y > COORDINATE_LIMIT do return -1
		if !mark_coordinate(&seen_x[0], x) || !mark_coordinate(&seen_y[0], y) do return -1
		points[point] = Point{x = x, y = y}
	}
	if n < 2 do return 0

	mut edges: [MAX_CANDIDATE_EDGES]Edge
	mut edge_count := 0
	for pass := 0; pass < 4; pass += 1 {
		mut sum_order: [MAX_N]Point_Order
		mut x_order: [MAX_N]Point_Order
		for point := 0; point < n; point += 1 {
			sum_order[point] = Point_Order{primary = points[point].x + points[point].y, secondary = points[point].x, id = point}
			x_order[point] = Point_Order{primary = points[point].x, secondary = 0, id = point}
		}
		sort.heap_sort_proc(sum_order[:n], compare_point_order)
		sort.heap_sort_proc(x_order[:n], compare_point_order)
		mut rank_of_id: [MAX_N]int
		mut id_at_rank: [MAX_N]int
		for rank := 0; rank < n; rank += 1 {
			point := x_order[rank].id
			rank_of_id[point] = rank
			id_at_rank[rank] = point
		}

		mut fenwick: [MAX_N+1]int
		for index := 0; index <= n; index += 1 { fenwick[index] = 0 }
		for order_index := 0; order_index < n; order_index += 1 {
			current := sum_order[order_index].id
			current_rank := rank_of_id[current]
			for {
				active_count := fenwick_prefix(&fenwick[0], current_rank+1)
				if active_count == 0 do break
				candidate_rank := fenwick_find_by_order(&fenwick[0], n, active_count)
				candidate := id_at_rank[candidate_rank]
				if points[current].x-points[current].y > points[candidate].x-points[candidate].y do break
				if edge_count >= MAX_CANDIDATE_EDGES do return -1
				u, v := current, candidate
				if u > v { u, v = v, u }
				dx := points[current].x-points[candidate].x
				dy := points[current].y-points[candidate].y
				if dx < 0 do dx = -dx
				if dy < 0 do dy = -dy
				edges[edge_count] = Edge{weight = dx+dy, u = u, v = v}
				edge_count += 1
				fenwick_add(&fenwick[0], candidate_rank+1, -1, n)
			}
			fenwick_add(&fenwick[0], current_rank+1, 1, n)
		}
		for point := 0; point < n; point += 1 {
			if pass % 2 == 0 {
				temporary := points[point].x
				points[point].x = points[point].y
				points[point].y = temporary
			} else {
				points[point].x = -points[point].x
			}
		}
	}

	sort.heap_sort_proc(edges[:edge_count], compare_edge_order)
	mut parent: [MAX_N]int
	mut size: [MAX_N]int
	for point := 0; point < n; point += 1 { parent[point] = point; size[point] = 1 }
	mut total := i64(0)
	mut accepted := 0
	for index := 0; index < edge_count; index += 1 {
		edge := edges[index]
		left := find_root(&parent[0], edge.u)
		right := find_root(&parent[0], edge.v)
		if left == right do continue
		if size[left] < size[right] {
			parent[left] = right
			size[right] += size[left]
		} else {
			parent[right] = left
			size[left] += size[right]
		}
		total += edge.weight
		accepted += 1
		if accepted+1 == n do break
	}
	if accepted+1 != n do return -1
	return total
}
