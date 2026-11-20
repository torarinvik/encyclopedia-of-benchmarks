package zielonka_parity_game_solver

import "core:c"

ZPG_MAX_VERTICES :: 8
ZPG_MAX_EDGES :: 20
ZPG_MAX_PARSEABLE_INPUT :: 59

zpg_attractor :: proc(active: i64, player: i64, target: i64, owners: []i64,
                      adjacency: []i64, n: int) -> i64 {
	attracted := target
	for {
		additions: i64 = 0
		for vertex := 0; vertex < n; vertex += 1 {
			bit := i64(1) << vertex
			if active&bit == 0 || attracted&bit != 0 do continue
			successors := adjacency[vertex] & active
			if owners[vertex] == player {
				if successors&attracted != 0 do additions |= bit
			} else if successors != 0 && successors&(~attracted) == 0 {
				additions |= bit
			}
		}
		if additions == 0 do return attracted
		attracted |= additions
	}
}

zpg_solve :: proc(active: i64, owners: []i64, priorities: []i64,
                  adjacency: []i64, n: int) -> i64 {
	if active == 0 do return 0
	lowest: i64 = 6
	for vertex := 0; vertex < n; vertex += 1 {
		if active&(i64(1)<<vertex) != 0 && priorities[vertex] < lowest do lowest = priorities[vertex]
	}
	player := lowest & 1
	target: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 {
		if active&(i64(1)<<vertex) != 0 && priorities[vertex] == lowest do target |= i64(1) << vertex
	}
	first := zpg_attractor(active, player, target, owners, adjacency, n)
	remainder := active & (~first)
	even_first := zpg_solve(remainder, owners, priorities, adjacency, n)
	odd_first := remainder & (~even_first)
	opponent_region := even_first
	if player == 0 do opponent_region = odd_first
	if opponent_region == 0 {
		if player == 0 do return even_first | first
		return even_first
	}
	second := zpg_attractor(active, 1-player, opponent_region, owners, adjacency, n)
	even_second := zpg_solve(active & (~second), owners, priorities, adjacency, n)
	if player == 1 do return even_second | second
	return even_second
}

@(export)
zielonka_parity_game_solver :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > ZPG_MAX_PARSEABLE_INPUT do return -1
	vertex_raw, edge_raw := input[0], input[1]
	if vertex_raw < 1 || vertex_raw > ZPG_MAX_VERTICES || edge_raw < vertex_raw || edge_raw > ZPG_MAX_EDGES do return -1
	n, edge_count := int(vertex_raw), int(edge_raw)
	if length != c.size_t(2 + 2*n + 2*edge_count) do return -1
	owners: [ZPG_MAX_VERTICES]i64
	priorities: [ZPG_MAX_VERTICES]i64
	adjacency: [ZPG_MAX_VERTICES]i64
	outdegree: [ZPG_MAX_VERTICES]int
	cursor := c.size_t(2)
	for vertex := 0; vertex < n; vertex += 1 {
		owner, priority := input[cursor], input[cursor+1]
		cursor += 2
		if owner < 0 || owner > 1 || priority < 0 || priority > 5 do return -1
		owners[vertex], priorities[vertex] = owner, priority
	}
	for _ := 0; _ < edge_count; _ += 1 {
		source_raw, destination_raw := input[cursor], input[cursor+1]
		cursor += 2
		if source_raw < 0 || source_raw >= vertex_raw || destination_raw < 0 || destination_raw >= vertex_raw do return -1
		source, destination := int(source_raw), int(destination_raw)
		bit := i64(1) << destination
		if adjacency[source]&bit != 0 do return -1
		adjacency[source] |= bit
		outdegree[source] += 1
	}
	for vertex := 0; vertex < n; vertex += 1 do if outdegree[vertex] == 0 do return -1
	return zpg_solve((i64(1)<<n)-1, owners[:n], priorities[:n], adjacency[:n], n)
}
