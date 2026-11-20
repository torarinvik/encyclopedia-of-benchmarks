module oi_wiki_maximum_clique_branch_bound

const max_vertices = 24
const max_parseable_input = 26

struct Clique_Search {
	mut:
		adjacency [max_vertices]u64
		suffix_best [max_vertices]int
		best int
}

fn bit_count(bits_value u64) int {
	mut bits := bits_value
	mut count := 0
	for bits != 0 { bits &= bits - u64(1); count++ }
	return count
}

fn search_clique(mut search Clique_Search, candidates u64, chosen int) bool {
	if candidates == 0 {
		if chosen > search.best { search.best = chosen; return true }
		return false
	}
	mut remaining := candidates
	for remaining != 0 {
		if chosen + bit_count(remaining) <= search.best { return false }
		mut vertex := 0
		for (remaining & (u64(1) << vertex)) == 0 { vertex++ }
		bit := u64(1) << vertex
		remaining &= ~bit
		if chosen + search.suffix_best[vertex] <= search.best { return false }
		if search_clique(mut search, remaining & search.adjacency[vertex], chosen + 1) {
			return true
		}
	}
	return false
}

@[export: 'oi_wiki_maximum_clique_branch_bound']
pub fn oi_wiki_maximum_clique_branch_bound(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_vertices || length != usize(1 + n_value) { return -1 }
		n := int(n_value)
		domain := (u64(1) << n) - u64(1)
		mut search := Clique_Search{}
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
		for root := n - 1; root >= 0; root-- {
			greater := domain & ~((u64(1) << (root + 1)) - u64(1))
			search_clique(mut search, search.adjacency[root] & greater, 1)
			search.suffix_best[root] = search.best
		}
		return i64(search.best)
	}
}
