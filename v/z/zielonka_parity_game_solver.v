module zielonka_parity_game_solver

const max_vertices = 8
const max_edges = 20
const max_parseable_input = 59

fn zpg_attractor(active i64, player i64, target i64, owners [8]i64, adjacency [8]i64, n int) i64 {
	mut attracted := target
	for {
		mut additions := i64(0)
		for vertex in 0 .. n {
			bit := i64(1) << vertex
			if active & bit == 0 || attracted & bit != 0 { continue }
			successors := adjacency[vertex] & active
			if owners[vertex] == player {
				if successors & attracted != 0 { additions |= bit }
			} else if successors != 0 && successors & ~attracted == 0 {
				additions |= bit
			}
		}
		if additions == 0 { return attracted }
		attracted |= additions
	}
}

fn zpg_solve(active i64, owners [8]i64, priorities [8]i64, adjacency [8]i64, n int) i64 {
	if active == 0 { return 0 }
	mut lowest := i64(6)
	for vertex in 0 .. n {
		if active & (i64(1) << vertex) != 0 && priorities[vertex] < lowest {
			lowest = priorities[vertex]
		}
	}
	player := lowest & 1
	mut target := i64(0)
	for vertex in 0 .. n {
		if active & (i64(1) << vertex) != 0 && priorities[vertex] == lowest {
			target |= i64(1) << vertex
		}
	}
	first := zpg_attractor(active, player, target, owners, adjacency, n)
	remainder := active & ~first
	even_first := zpg_solve(remainder, owners, priorities, adjacency, n)
	odd_first := remainder & ~even_first
	opponent_region := if player == 1 { even_first } else { odd_first }
	if opponent_region == 0 {
		return even_first | (if player == 0 { first } else { 0 })
	}
	second := zpg_attractor(active, 1 - player, opponent_region, owners, adjacency, n)
	even_second := zpg_solve(active & ~second, owners, priorities, adjacency, n)
	return even_second | (if player == 1 { second } else { 0 })
}

@[export: 'zielonka_parity_game_solver']
pub fn zielonka_parity_game_solver(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > max_parseable_input { return -1 }
		vertex_raw, edge_raw := input[0], input[1]
		if vertex_raw < 1 || vertex_raw > max_vertices || edge_raw < vertex_raw || edge_raw > max_edges {
			return -1
		}
		n, edge_count := int(vertex_raw), int(edge_raw)
		if length != usize(2 + 2 * n + 2 * edge_count) { return -1 }
		mut owners := [8]i64{}
		mut priorities := [8]i64{}
		mut adjacency := [8]i64{}
		mut outdegree := [8]int{}
		mut cursor := 2
		for vertex in 0 .. n {
			owner, priority := input[cursor], input[cursor + 1]
			cursor += 2
			if owner < 0 || owner > 1 || priority < 0 || priority > 5 { return -1 }
			owners[vertex], priorities[vertex] = owner, priority
		}
		for _ in 0 .. edge_count {
			source_raw, destination_raw := input[cursor], input[cursor + 1]
			cursor += 2
			if source_raw < 0 || source_raw >= vertex_raw || destination_raw < 0 || destination_raw >= vertex_raw {
				return -1
			}
			source, destination := int(source_raw), int(destination_raw)
			bit := i64(1) << destination
			if adjacency[source] & bit != 0 { return -1 }
			adjacency[source] |= bit
			outdegree[source]++
		}
		for vertex in 0 .. n { if outdegree[vertex] == 0 { return -1 } }
		return zpg_solve((i64(1) << n) - 1, owners, priorities, adjacency, n)
	}
}
