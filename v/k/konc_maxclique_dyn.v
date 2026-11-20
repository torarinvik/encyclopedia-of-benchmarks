// Clean-room bounded MaxCliqueDyn-style colored branch and bound.
module konc_maxclique_dyn

const max_vertices = 24
const max_parseable_input = 26

struct Candidate {
mut:
	vertex int
	bound int
}

struct Search {
mut:
	adjacency [max_vertices]u64
	chosen [max_vertices]int
	chosen_count int
	best int
	steps [max_vertices + 2]int
	prior_child_steps [max_vertices + 2]int
	total_color_calls int
}

fn degree_order(search &Search, vertices []int) []Candidate {
	mut items := []Candidate{cap: vertices.len}
	mut maximum_degree := 0
	for vertex in vertices {
		mut degree := 0
		for other in vertices {
			if search.adjacency[vertex] & (u64(1) << other) != 0 { degree++ }
		}
		items << Candidate{vertex, degree}
		if degree > maximum_degree { maximum_degree = degree }
	}
	for i := 1; i < items.len; i++ {
		id := items[i].vertex
		degree := items[i].bound
		mut j := i
		for j > 0 && (items[j - 1].bound < degree ||
			(items[j - 1].bound == degree && items[j - 1].vertex > id)) {
			items[j] = items[j - 1]
			j--
		}
		items[j] = Candidate{id, degree}
	}
	for i in 0 .. items.len {
		items[i].bound = min(i, maximum_degree) + 1
	}
	return items
}

fn expand(mut search Search, candidates []Candidate, level int) {
	search.steps[level] += search.steps[level - 1] - search.prior_child_steps[level]
	search.prior_child_steps[level] = search.steps[level - 1]
	mut count := candidates.len
	for count > 0 {
		if search.chosen_count + candidates[count - 1].bound <= search.best { return }
		vertex := candidates[count - 1].vertex
		search.chosen[search.chosen_count] = vertex
		search.chosen_count++
		mut neighbors := []int{cap: count}
		for i in 0 .. count - 1 {
			other := candidates[i].vertex
			if search.adjacency[vertex] & (u64(1) << other) != 0 { neighbors << other }
		}
		if neighbors.len > 0 {
			prior_steps := search.steps[level]
			search.steps[level]++
			search.total_color_calls++
			if i64(prior_steps) * 1000 < i64(search.total_color_calls) * 25 {
				reordered := degree_order(search, neighbors)
				neighbors.clear()
				for item in reordered { neighbors << item.vertex }
			}
			mut class_masks := []u64{len: neighbors.len, init: 0}
			mut colors := []int{len: neighbors.len, init: 0}
			mut class_count := 0
			for i, candidate in neighbors {
				mut color := 0
				for color < class_count && class_masks[color] & search.adjacency[candidate] != 0 { color++ }
				if color == class_count { class_count++ }
				colors[i] = color + 1
				class_masks[color] |= u64(1) << candidate
			}
			minimum_color := max(search.best - search.chosen_count + 1, 1)
			mut child := []Candidate{cap: neighbors.len}
			for color in minimum_color .. class_count + 1 {
				for i, candidate in neighbors {
					if colors[i] == color { child << Candidate{candidate, color} }
				}
			}
			expand(mut search, child, level + 1)
		} else if search.chosen_count > search.best {
			search.best = search.chosen_count
		}
		search.chosen_count--
		count--
	}
}

@[export: 'konc_maxclique_dyn']
pub fn konc_maxclique_dyn(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input { return -1 }
		n64 := input[0]
		if n64 < 0 || n64 > max_vertices || length != usize(1 + n64) { return -1 }
		n := int(n64)
		domain := (u64(1) << n) - u64(1)
		mut search := Search{}
		for vertex in 0 .. n {
			row := input[1 + vertex]
			if row < 0 || (u64(row) & ~domain) != 0 { return -1 }
			search.adjacency[vertex] = u64(row)
			if search.adjacency[vertex] & (u64(1) << vertex) != 0 { return -1 }
		}
		for left in 0 .. n {
			for right in left + 1 .. n {
				forward := search.adjacency[left] & (u64(1) << right) != 0
				reverse := search.adjacency[right] & (u64(1) << left) != 0
				if forward != reverse { return -1 }
			}
		}
		if n == 0 { return 0 }
		mut vertices := []int{cap: n}
		for vertex in 0 .. n { vertices << vertex }
		roots := degree_order(search, vertices)
		expand(mut search, roots, 1)
		return i64(search.best)
	}
}
