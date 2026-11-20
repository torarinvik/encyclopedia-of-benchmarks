package konc_maxclique_dyn

import "core:c"

MAX_VERTICES :: 24
MAX_PARSEABLE_INPUT :: 26

Candidate :: struct { vertex: int, bound: int }
Search :: struct {
	adjacency: [MAX_VERTICES]u64,
	chosen: [MAX_VERTICES]int,
	chosen_count: int,
	best: int,
	steps: [MAX_VERTICES + 2]int,
	prior_child_steps: [MAX_VERTICES + 2]int,
	total_color_calls: int,
}

degree_order :: proc "contextless" (search: ^Search, vertices: []int,
									ordered: []Candidate) {
	ids: [MAX_VERTICES]int
	degrees: [MAX_VERTICES]int = {}
	maximum_degree := 0
	for i, vertex in vertices {
		ids[i] = vertex
		for other in vertices {
			if search.adjacency[vertex]&(u64(1)<<other) != 0 do degrees[i] += 1
		}
		maximum_degree = max(maximum_degree, degrees[i])
	}
	for i := 1; i < len(vertices); i += 1 {
		id := ids[i]
		degree := degrees[i]
		j := i
		for j > 0 && (degrees[j-1] < degree || (degrees[j-1] == degree && ids[j-1] > id)) {
			ids[j] = ids[j-1]
			degrees[j] = degrees[j-1]
			j -= 1
		}
		ids[j] = id
		degrees[j] = degree
	}
	for i in 0..<len(vertices) {
		ordered[i] = Candidate{ids[i], min(i, maximum_degree) + 1}
	}
}

expand :: proc "contextless" (search: ^Search, candidates: []Candidate, level: int) {
	search.steps[level] += search.steps[level-1] - search.prior_child_steps[level]
	search.prior_child_steps[level] = search.steps[level-1]
	count := len(candidates)
	for count > 0 {
		if search.chosen_count + candidates[count-1].bound <= search.best do return
		vertex := candidates[count-1].vertex
		search.chosen[search.chosen_count] = vertex
		search.chosen_count += 1
		neighbors: [MAX_VERTICES]int
	neighbor_count := 0
	for i := 0; i < count-1; i += 1 {
		other := candidates[i].vertex
		if search.adjacency[vertex]&(u64(1)<<other) != 0 {
			neighbors[neighbor_count] = other
			neighbor_count += 1
		}
	}
	if neighbor_count > 0 {
		prior_steps := search.steps[level]
		search.steps[level] += 1
		search.total_color_calls += 1
		if i64(prior_steps)*1000 < i64(search.total_color_calls)*25 {
			reordered: [MAX_VERTICES]Candidate
			degree_order(search, neighbors[:neighbor_count], reordered[:neighbor_count])
			for i in 0..<neighbor_count { neighbors[i] = reordered[i].vertex }
		}
		class_masks: [MAX_VERTICES]u64 = {}
		colors: [MAX_VERTICES]int
	class_count := 0
	for i in 0..<neighbor_count {
		color := 0
		for color < class_count && class_masks[color]&search.adjacency[neighbors[i]] != 0 { color += 1 }
		if color == class_count { class_count += 1 }
		colors[i] = color + 1
		class_masks[color] |= u64(1) << neighbors[i]
	}
	minimum_color := max(search.best-search.chosen_count+1, 1)
	child: [MAX_VERTICES]Candidate
	child_count := 0
	for color := minimum_color; color <= class_count; color += 1 {
		for i in 0..<neighbor_count {
			if colors[i] == color {
				child[child_count] = Candidate{neighbors[i], color}
				child_count += 1
			}
		}
	}
			expand(search, child[:child_count], level+1)
	} else if search.chosen_count > search.best {
		search.best = search.chosen_count
	}
	search.chosen_count -= 1
	count -= 1
	}
}

@(export)
konc_maxclique_dyn :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	n64 := input[0]
	if n64 < 0 || n64 > MAX_VERTICES || length != c.size_t(n64+1) do return -1
	n := int(n64)
	domain := (u64(1)<<n)-1
	search := Search{}
	for vertex := 0; vertex < n; vertex += 1 {
		row := input[1+vertex]
		if row < 0 || (u64(row)&~domain) != 0 do return -1
		search.adjacency[vertex] = u64(row)
		if search.adjacency[vertex]&(u64(1)<<vertex) != 0 do return -1
	}
	for left := 0; left < n; left += 1 {
		for right := left+1; right < n; right += 1 {
			forward := search.adjacency[left]&(u64(1)<<right) != 0
			reverse := search.adjacency[right]&(u64(1)<<left) != 0
			if forward != reverse do return -1
		}
	}
	if n == 0 do return 0
	vertices: [MAX_VERTICES]int
	roots: [MAX_VERTICES]Candidate
	for i := 0; i < n; i += 1 { vertices[i] = i }
	degree_order(&search, vertices[:n], roots[:n])
	expand(&search, roots[:n], 1)
	return i64(search.best)
}
