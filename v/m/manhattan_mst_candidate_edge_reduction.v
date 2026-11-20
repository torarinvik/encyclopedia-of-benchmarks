module manhattan_mst_candidate_edge_reduction

const (
	max_n = 31
	max_input_length = 1 + 2 * max_n
	max_candidate_edges = 4 * max_n
	coordinate_bitset_words = 32
	coordinate_limit = i64(1_000)
)

struct Point {
	x i64
	y i64
}

struct Edge {
	weight i64
	u int
	v int
}

struct PointOrder {
	primary i64
	secondary i64
	id int
}

fn mark_coordinate(mut seen [coordinate_bitset_words]u64, coordinate i64) bool {
	index := int(coordinate + coordinate_limit)
	word := index / 64
	mask := u64(1) << (index % 64)
	if seen[word] & mask != 0 { return false }
	seen[word] |= mask
	return true
}

fn fenwick_add(mut tree [max_n + 1]int, index_input int, delta int, count int) {
	mut index := index_input
	for index <= count {
		tree[index] += delta
		index += index & -index
	}
}

fn fenwick_prefix(tree &[max_n + 1]int, index_input int) int {
	mut index := index_input
	mut total := 0
	for index > 0 {
		total += tree[index]
		index -= index & -index
	}
	return total
}

fn fenwick_find_by_order(tree &[max_n + 1]int, count int, order int) int {
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

fn find_root(mut parent [max_n]int, node_input int) int {
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

@[export: 'manhattan_mst_candidate_edge_reduction']
pub fn manhattan_mst_candidate_edge_reduction(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		n_word := input[0]
		if n_word < 0 || n_word > max_n { return -1 }
		n := int(n_word)
		if length != usize(1 + 2 * n) { return -1 }

		mut points := [max_n]Point{}
		mut seen_x := [coordinate_bitset_words]u64{}
		mut seen_y := [coordinate_bitset_words]u64{}
		for point in 0 .. n {
			x := input[1 + 2 * point]
			y := input[2 + 2 * point]
			if x < -coordinate_limit || x > coordinate_limit || y < -coordinate_limit || y > coordinate_limit { return -1 }
			if !mark_coordinate(mut seen_x, x) || !mark_coordinate(mut seen_y, y) { return -1 }
			points[point] = Point{x: x, y: y}
		}
		if n < 2 { return 0 }

		mut edges := []Edge{cap: max_candidate_edges}
		mut edge_count := 0
		for pass in 0 .. 4 {
			mut sum_order := []PointOrder{cap: n}
			mut x_order := []PointOrder{cap: n}
			for point in 0 .. n {
				sum_order << PointOrder{primary: points[point].x + points[point].y, secondary: points[point].x, id: point}
				x_order << PointOrder{primary: points[point].x, secondary: 0, id: point}
			}
			sum_order.sort(a, b) {
				if a.primary != b.primary { return a.primary < b.primary }
				if a.secondary != b.secondary { return a.secondary < b.secondary }
				return a.id < b.id
			}
			x_order.sort(a, b) {
				if a.primary != b.primary { return a.primary < b.primary }
				return a.id < b.id
			}
			mut rank_of_id := [max_n]int{}
			mut id_at_rank := [max_n]int{}
			for rank in 0 .. n {
				point := x_order[rank].id
				rank_of_id[point] = rank
				id_at_rank[rank] = point
			}

			mut fenwick := [max_n + 1]int{}
			for order_index in 0 .. n {
				current := sum_order[order_index].id
				current_rank := rank_of_id[current]
				for {
					active_count := fenwick_prefix(&fenwick, current_rank + 1)
					if active_count == 0 { break }
					candidate_rank := fenwick_find_by_order(&fenwick, n, active_count)
					candidate := id_at_rank[candidate_rank]
					if points[current].x - points[current].y > points[candidate].x - points[candidate].y { break }
					if edge_count >= max_candidate_edges { return -1 }
					u, v := current, candidate
					if u > v { u, v = v, u }
					dx := points[current].x - points[candidate].x
					dy := points[current].y - points[candidate].y
					if dx < 0 { dx = -dx }
					if dy < 0 { dy = -dy }
				edges << Edge{weight: dx + dy, u: u, v: v}
					edge_count++
					fenwick_add(mut fenwick, candidate_rank + 1, -1, n)
				}
				fenwick_add(mut fenwick, current_rank + 1, 1, n)
			}
			for point in 0 .. n {
				if pass % 2 == 0 {
					temporary := points[point].x
					points[point].x = points[point].y
					points[point].y = temporary
				} else {
					points[point].x = -points[point].x
				}
			}
		}

		edges.sort(a, b) {
			if a.weight != b.weight { return a.weight < b.weight }
			if a.u != b.u { return a.u < b.u }
			return a.v < b.v
		}
		mut parent := [max_n]int{}
		mut size := [max_n]int{}
		for point in 0 .. n {
			parent[point] = point
			size[point] = 1
		}
		mut total := i64(0)
		mut accepted := 0
		for edge_index in 0 .. edge_count {
			edge := edges[edge_index]
			left := find_root(mut parent, edge.u)
			right := find_root(mut parent, edge.v)
			if left == right { continue }
			if size[left] < size[right] {
				parent[left] = right
				size[right] += size[left]
			} else {
				parent[right] = left
				size[left] += size[right]
			}
			total += edge.weight
			accepted++
			if accepted + 1 == n { break }
		}
		if accepted + 1 != n { return -1 }
		return total
	}
}
