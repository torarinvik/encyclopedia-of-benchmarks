// Clean-room fixed-embedding angle-assignment flow profile, DOI 653.
package upward_planarity_angle_assignment

import "core:c"

MAX_N :: 8
MAX_M :: 18
MAX_F :: 12
MAX_INPUT :: 124
MAX_OUTPUT_WORDS :: 26

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

augment_terminal :: proc "contextless" (ordinal, slot_count: int,
	terminals: [MAX_N]int, slots: [MAX_N]int,
	incident: [MAX_N][MAX_F]bool,
	owner: ^[MAX_N]int, seen: ^[MAX_N]bool,
	assigned: ^[MAX_N]int) -> bool {
	vertex := terminals[ordinal]
	for slot := 0; slot < slot_count; slot += 1 {
		face := slots[slot]
		if incident[vertex][face] && !seen[slot] {
			seen[slot] = true
			old_owner := owner[slot]
			if old_owner < 0 || augment_terminal(old_owner, slot_count, terminals, slots,
				incident, owner, seen, assigned) {
				owner[slot] = ordinal
				assigned[ordinal] = slot
				return true
			}
		}
	}
	return false
}

can_match_suffix :: proc "contextless" (start, terminal_count, face_count: int,
	terminals: [MAX_N]int, capacities: [MAX_F]int,
	incident: [MAX_N][MAX_F]bool) -> bool {
	var slots: [MAX_N]int
	slot_count := 0
	for face := 0; face < face_count; face += 1 {
		for unit := 0; unit < capacities[face]; unit += 1 {
			slots[slot_count] = face
			slot_count += 1
		}
	}
	var owner, assigned: [MAX_N]int
	for slot := 0; slot < MAX_N; slot += 1 { owner[slot], assigned[slot] = -1, -1 }
	for ordinal := start; ordinal < terminal_count; ordinal += 1 {
		var seen: [MAX_N]bool
		if !augment_terminal(ordinal, slot_count, terminals, slots, incident,
			&owner, &seen, &assigned) {
			return false
		}
	}
	return true
}

@(export)
upward_planarity_angle_assignment :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64, m64, f64, outer64 := input[0], input[1], input[2], input[3]
	if n64 < 2 || n64 > MAX_N || m64 < 1 || m64 > MAX_M || f64 < 1 || f64 > MAX_F ||
		outer64 < 0 || outer64 >= f64 || length != c.size_t(4 + 6*m64 + f64) do return -1
	n, m, face_count, outer := int(n64), int(m64), int(f64), int(outer64)

	var edge_u, edge_v: [MAX_M]int
	var adjacent, outgoing: [MAX_N][MAX_N]bool
	var indegree: [MAX_N]int
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[4+2*edge], input[5+2*edge]
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 do return -1
		u, v := int(u64), int(v64)
		if edge > 0 && (edge_u[edge-1] > u || edge_u[edge-1] == u && edge_v[edge-1] >= v) do return -1
		for prior := 0; prior < edge; prior += 1 {
			if edge_u[prior] == u && edge_v[prior] == v || edge_u[prior] == v && edge_v[prior] == u do return -1
		}
		edge_u[edge], edge_v[edge] = u, v
		adjacent[u][v], adjacent[v][u] = true, true
		outgoing[u][v] = true
		indegree[v] += 1
	}

	var walk_length: [MAX_F]int
	var walk_from, walk_to: [2*MAX_M]int
	var dart: [MAX_N][MAX_N]bool
	cursor, total := 4+2*m, 0
	for face := 0; face < face_count; face += 1 {
		k64 := input[cursor]
		cursor += 1
		if k64 < 1 || k64 > 2*m64 || total+int(k64) > 2*m do return -1
		k := int(k64)
		walk_length[face] = k
		for step := 0; step < k; step += 1 {
			u64, v64 := input[cursor], input[cursor+1]
			cursor += 2
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 do return -1
			u, v := int(u64), int(v64)
			if !adjacent[u][v] || dart[u][v] do return -1
			dart[u][v] = true
			walk_from[total], walk_to[total] = u, v
			total += 1
		}
	}
	if cursor != int(length) || total != 2*m || n-m+face_count != 2 do return -1
	for edge := 0; edge < m; edge += 1 {
		if !dart[edge_u[edge]][edge_v[edge]] || !dart[edge_v[edge]][edge_u[edge]] do return -1
	}

	var successor: [MAX_N][MAX_N]int
	var first_corner: [MAX_F][MAX_N]int
	var incident: [MAX_N][MAX_F]bool
	var switches: [MAX_F][2]int
	for face := 0; face < MAX_F; face += 1 {
		for vertex := 0; vertex < MAX_N; vertex += 1 { first_corner[face][vertex] = -1 }
	}
	for vertex := 0; vertex < MAX_N; vertex += 1 {
		for neighbor := 0; neighbor < MAX_N; neighbor += 1 { successor[vertex][neighbor] = -1 }
	}
	cursor = 0
	for face := 0; face < face_count; face += 1 {
		base, k := cursor, walk_length[face]
		for step := 0; step < k; step += 1 {
			u, v := walk_from[cursor], walk_to[cursor]
			next := walk_to[base+(step+1)%k]
			if v != walk_from[base+(step+1)%k] || successor[v][u] >= 0 do return -1
			successor[v][u] = next
			if first_corner[face][v] < 0 do first_corner[face][v] = step
			incident[v][face] = true
			if outgoing[v][u] && outgoing[v][next] { switches[face][0] += 1 }
			if !outgoing[v][u] && !outgoing[v][next] { switches[face][1] += 1 }
			cursor += 1
		}
	}

	var reached: [MAX_N]bool
	var queue: [MAX_N]int
	head, tail := 0, 0
	reached[0] = true
	queue[tail] = 0
	tail += 1
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < n; v += 1 {
			if adjacent[u][v] && !reached[v] {
				reached[v] = true
				queue[tail] = v
				tail += 1
			}
		}
	}
	for vertex := 0; vertex < n; vertex += 1 { if !reached[vertex] do return -1 }

	var degree: [MAX_N]int
	head, tail = 0, 0
	for vertex := 0; vertex < n; vertex += 1 {
		degree[vertex] = indegree[vertex]
		if degree[vertex] == 0 { queue[tail] = vertex; tail += 1 }
	}
	removed := 0
	for head < tail {
		u := queue[head]
		head += 1
		removed += 1
		for v := 0; v < n; v += 1 {
			if outgoing[u][v] {
				degree[v] -= 1
				if degree[v] == 0 { queue[tail] = v; tail += 1 }
			}
		}
	}
	if removed != n do return -1

	for vertex := 0; vertex < n; vertex += 1 {
		degree_count := 0
		for neighbor := 0; neighbor < n; neighbor += 1 { if adjacent[vertex][neighbor] do degree_count += 1 }
		if degree_count == 0 do return -1
		start := -1
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if adjacent[vertex][neighbor] {
				if successor[vertex][neighbor] < 0 do return -1
				start = neighbor
			}
		}
		current, seen_count, transitions := start, 0, 0
		for {
			if current < 0 || seen_count >= degree_count do return -1
			seen_count += 1
			next := successor[vertex][current]
			if next < 0 || next >= n do return -1
			if outgoing[vertex][current] != outgoing[vertex][next] do transitions += 1
			current = next
			if current == start do break
		}
		if seen_count != degree_count || transitions != 0 && transitions != 2 do return -1
	}
	for face := 0; face < face_count; face += 1 {
		if switches[face][0] != switches[face][1] do return -1
	}

	var face_capacity: [MAX_F]int
	var capacity_valid := true
	total_capacity, terminal_count := 0, 0
	for face := 0; face < face_count; face += 1 {
		adjustment := -1
		if face == outer { adjustment = 1 }
		face_capacity[face] = switches[face][0] + adjustment
		if face_capacity[face] < 0 { capacity_valid = false }
		total_capacity += face_capacity[face]
	}
	var terminals: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		out_degree := 0
		for neighbor := 0; neighbor < n; neighbor += 1 { if outgoing[vertex][neighbor] do out_degree += 1 }
		if indegree[vertex] == 0 || out_degree == 0 {
			terminals[terminal_count] = vertex
			terminal_count += 1
		}
	}
	if total_capacity != terminal_count { capacity_valid = false }
	output_bytes := 8 * (2 + 3 * terminal_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	var chosen_face: [MAX_N]int
	var feasible := capacity_valid
	if feasible {
		var remaining: [MAX_F]int
		for face := 0; face < face_count; face += 1 { remaining[face] = face_capacity[face] }
		for ordinal := 0; ordinal < terminal_count; ordinal += 1 {
			picked := false
			vertex := terminals[ordinal]
			for face := 0; face < face_count; face += 1 {
				if remaining[face] <= 0 || !incident[vertex][face] do continue
				remaining[face] -= 1
				if can_match_suffix(ordinal + 1, terminal_count, face_count,
					terminals, remaining, incident) {
					chosen_face[ordinal] = face
					picked = true
					break
				}
				remaining[face] += 1
			}
			if !picked {
				feasible = false
				break
			}
		}
	}

	var words: [MAX_OUTPUT_WORDS]i64
	words[0] = 0
	if feasible { words[0] = 1 }
	words[1] = i64(terminal_count)
	position := 2
	for ordinal := 0; ordinal < terminal_count; ordinal += 1 {
		if feasible {
			face := chosen_face[ordinal]
			words[position] = i64(terminals[ordinal])
			words[position+1] = i64(face)
			words[position+2] = i64(first_corner[face][terminals[ordinal]])
		} else {
			words[position], words[position+1], words[position+2] = -1, -1, -1
		}
		position += 3
	}
	for index := 0; index < position; index += 1 { store_i64_le(&output[0], 8*index, words[index]) }
	return i64(output_bytes)
}
