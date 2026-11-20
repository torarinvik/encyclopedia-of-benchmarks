package canonical_order_schnyder_realizer

import "core:c"

MAX_N :: 8
MAX_INPUT :: 49
MAX_DARTS :: 48

Embedding :: struct {
	n, u, v, w: int,
	degree: [MAX_N]int,
	rotation: [MAX_N][MAX_N]int,
	adjacent: [MAX_N][MAX_N]bool,
}

next_active :: proc "contextless" (g: ^Embedding, active: [MAX_N]bool, source, target: int) -> int {
	source_position := -1
	remaining := 0
	for i := 0; i < g.degree[target]; i += 1 {
		neighbor := g.rotation[target][i]
		if !active[neighbor] { continue }
		remaining += 1
		if neighbor == source { source_position = i }
	}
	if remaining < 2 || source_position < 0 { return -1 }
	for step := 1; step <= g.degree[target]; step += 1 {
		neighbor := g.rotation[target][(source_position + step) % g.degree[target]]
		if active[neighbor] { return neighbor }
	}
	return -1
}

face_cycle :: proc "contextless" (g: ^Embedding, active: [MAX_N]bool, first, second: int,
	cycle: ^[MAX_DARTS]int) -> int {
	seen: [MAX_N][MAX_N]bool
	source, target := first, second
	length := 0
	for step := 0; step < MAX_DARTS; step += 1 {
		if source < 0 || source >= g.n || target < 0 || target >= g.n || !active[source] || !active[target] ||
			!g.adjacent[source][target] || seen[source][target] { return -1 }
		seen[source][target] = true
		cycle[length] = source
		length += 1
		following := next_active(g, active, source, target)
		if following < 0 { return -1 }
		source, target = target, following
		if source == first && target == second { return length }
	}
	return -1
}

parse_embedding :: proc "contextless" (input: [^]i64, length: int, g: ^Embedding) -> bool {
	if input == nil || length < 4 || length > MAX_INPUT { return false }
	n_raw := input[0]
	if n_raw < 3 || n_raw > MAX_N { return false }
	g.n = int(n_raw)
	if input[1] < 0 || input[1] >= n_raw || input[2] < 0 || input[2] >= n_raw || input[3] < 0 || input[3] >= n_raw ||
		input[1] == input[2] || input[1] == input[3] || input[2] == input[3] { return false }
	g.u, g.v, g.w = int(input[1]), int(input[2]), int(input[3])
	offset, degree_sum := 4, 0
	for vertex := 0; vertex < g.n; vertex += 1 {
		if offset >= length { return false }
		degree_raw := input[offset]
		offset += 1
		if degree_raw < 2 || degree_raw >= n_raw || offset + int(degree_raw) > length { return false }
		degree := int(degree_raw)
		g.degree[vertex] = degree
		degree_sum += degree
		row_seen: [MAX_N]bool
		for rank := 0; rank < degree; rank += 1 {
			raw := input[offset]
			offset += 1
			if raw < 0 || raw >= n_raw || raw == int64(vertex) { return false }
			neighbor := int(raw)
			if row_seen[neighbor] { return false }
			row_seen[neighbor] = true
			g.rotation[vertex][rank] = neighbor
			g.adjacent[vertex][neighbor] = true
		}
	}
	if offset != length || degree_sum != 6 * g.n - 12 { return false }
	edge_count := 0
	for a := 0; a < g.n; a += 1 {
		for b := 0; b < g.n; b += 1 {
			if g.adjacent[a][b] != g.adjacent[b][a] { return false }
			if a < b && g.adjacent[a][b] { edge_count += 1 }
		}
	}
	if edge_count != 3 * g.n - 6 { return false }
	reached: [MAX_N]bool
	stack: [MAX_N]int
	stack_size, reached_count := 1, 0
	reached[0] = true
	for stack_size > 0 {
		stack_size -= 1
		vertex := stack[stack_size]
		reached_count += 1
		for neighbor := 0; neighbor < g.n; neighbor += 1 {
			if g.adjacent[vertex][neighbor] && !reached[neighbor] {
				reached[neighbor] = true
				stack[stack_size] = neighbor
				stack_size += 1
			}
		}
	}
	if reached_count != g.n { return false }
	all_active: [MAX_N]bool
	for i := 0; i < g.n; i += 1 { all_active[i] = true }
	seen_dart: [MAX_N][MAX_N]bool
	face_count, visited_darts := 0, 0
	for source := 0; source < g.n; source += 1 {
		for target := 0; target < g.n; target += 1 {
			if !g.adjacent[source][target] || seen_dart[source][target] { continue }
			cycle: [MAX_DARTS]int
			face_length := face_cycle(g, all_active, source, target, &cycle)
			if face_length != 3 { return false }
			face_count += 1
			for i := 0; i < face_length; i += 1 {
				a, b := cycle[i], cycle[(i + 1) % face_length]
				if seen_dart[a][b] { return false }
				seen_dart[a][b] = true
				visited_darts += 1
			}
		}
	}
	if face_count != 2 * g.n - 4 || visited_darts != 6 * g.n - 12 { return false }
	outer: [MAX_DARTS]int
	return face_cycle(g, all_active, g.u, g.v, &outer) == 3 && outer[0] == g.u && outer[1] == g.v && outer[2] == g.w
}

boundary_path :: proc "contextless" (g: ^Embedding, active: [MAX_N]bool, path: ^[MAX_N]int) -> int {
	cycle: [MAX_DARTS]int
	length := face_cycle(g, active, g.u, g.v, &cycle)
	if length < 3 { return -1 }
	count := 0
	path[count] = g.u
	count += 1
	for i := length - 1; i >= 2; i -= 1 {
		path[count] = cycle[i]
		count += 1
	}
	path[count] = g.v
	return count + 1
}

peel_choice :: proc "contextless" (g: ^Embedding, path: [MAX_N]int, length: int) -> int {
	chord: [MAX_N][MAX_N]bool
	chord_count := 0
	for left := 0; left < length; left += 1 {
		for right := left + 2; right < length; right += 1 {
			if left == 0 && right == length - 1 { continue }
			if g.adjacent[path[left]][path[right]] { chord[left][right] = true; chord_count += 1 }
		}
	}
	eligible: [MAX_N]bool
	if chord_count == 0 {
		for i := 1; i + 1 < length; i += 1 { eligible[path[i]] = true }
	} else {
		for left := 0; left < length; left += 1 {
			for right := left + 2; right < length; right += 1 {
				if !chord[left][right] { continue }
				minimal := true
				for a := left; a < right && minimal; a += 1 {
					for b := a + 2; b <= right; b += 1 {
						if chord[a][b] && (a != left || b != right) { minimal = false }
					}
				}
				if minimal { for i := left + 1; i < right; i += 1 { eligible[path[i]] = true } }
			}
		}
	}
	for vertex := 0; vertex < g.n; vertex += 1 { if eligible[vertex] { return vertex } }
	return -1
}

peel_contains :: proc "contextless" (g: ^Embedding, path: [MAX_N]int, length: int, candidate: int) -> bool {
	chord: [MAX_N][MAX_N]bool
	chord_count := 0
	for left := 0; left < length; left += 1 {
		for right := left + 2; right < length; right += 1 {
			if left == 0 && right == length - 1 { continue }
			if g.adjacent[path[left]][path[right]] { chord[left][right] = true; chord_count += 1 }
		}
	}
	eligible: [MAX_N]bool
	if chord_count == 0 {
		for i := 1; i + 1 < length; i += 1 { eligible[path[i]] = true }
	} else {
		for left := 0; left < length; left += 1 {
			for right := left + 2; right < length; right += 1 {
				if !chord[left][right] { continue }
				minimal := true
				for a := left; a < right && minimal; a += 1 {
					for b := a + 2; b <= right; b += 1 {
						if chord[a][b] && (a != left || b != right) { minimal = false }
					}
				}
				if minimal { for i := left + 1; i < right; i += 1 { eligible[path[i]] = true } }
			}
		}
	}
	return candidate >= 0 && candidate < g.n && eligible[candidate]
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
canonical_order_schnyder_realizer :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 57 { return -1 }
	if input[0] < 3 || input[0] > MAX_N { return -1 }
	n := int(input[0])
	if int(length) < n + 4 { return -1 }
	graph_length := int(length) - n
	g: Embedding
	if !parse_embedding(input, graph_length, &g) || g.n != n { return -1 }
	order: [MAX_N]int
	order_seen: [MAX_N]bool
	for i := 0; i < n; i += 1 {
		raw := input[graph_length + i]
		if raw < 0 || raw >= i64(n) || order_seen[int(raw)] { return -1 }
		order[i] = int(raw)
		order_seen[order[i]] = true
	}
	if order[0] != g.u || order[1] != g.v || order[n - 1] != g.w { return -1 }
	active: [MAX_N]bool
	for i := 0; i < n; i += 1 { active[i] = true }
	path: [MAX_N]int
	if n > 3 {
		active[g.w] = false
		path_length := boundary_path(&g, active, &path)
		if path_length < 3 { return -1 }
		reverse_index := n - 2
		for reverse_index >= 3 {
			candidate := order[reverse_index]
			if candidate == g.u || candidate == g.v || !active[candidate] || !peel_contains(&g, path, path_length, candidate) { return -1 }
			active[candidate] = false
			path_length = boundary_path(&g, active, &path)
			if path_length < 3 { return -1 }
			if reverse_index == 3 { break }
			reverse_index -= 1
		}
		if path_length != 3 || path[0] != g.u || path[1] != order[2] || path[2] != g.v { return -1 }
	} else if order[2] != g.w { return -1 }
	position: [MAX_N]int
	for i := 0; i < n; i += 1 { position[order[i]] = i }
	words: [1 + 4 * (MAX_N - 3)]i64
	words[0] = i64(n)
	count := 1
	for rank := 2; rank < n - 1; rank += 1 {
		vertex := order[rank]
		left, right := -1, -1
		if rank == 2 {
			if !g.adjacent[vertex][g.u] || !g.adjacent[vertex][g.v] { return -1 }
			left, right = g.u, g.v
		} else {
			prefix: [MAX_N]bool
			for i := 0; i < rank; i += 1 { prefix[order[i]] = true }
			boundary: [MAX_N]int
			boundary_length := boundary_path(&g, prefix, &boundary)
			if boundary_length < 3 { return -1 }
			ended, boundary_count, predecessor_count := false, 0, 0
			for i := 0; i < boundary_length; i += 1 {
				if g.adjacent[vertex][boundary[i]] {
					if ended { return -1 }
					if left < 0 { left = boundary[i] }
					right = boundary[i]
					boundary_count += 1
				} else if left >= 0 { ended = true }
			}
			for i := 0; i < rank; i += 1 { if g.adjacent[vertex][order[i]] { predecessor_count += 1 } }
			if boundary_count < 2 || boundary_count != predecessor_count { return -1 }
		}
		successor := -1
		for other := 0; other < n; other += 1 {
			if position[other] > rank && g.adjacent[vertex][other] && (successor < 0 || position[other] > position[successor]) { successor = other }
		}
		if successor < 0 { return -1 }
		words[count], words[count + 1], words[count + 2], words[count + 3] = i64(vertex), i64(left), i64(right), i64(successor)
		count += 4
	}
	required := c.size_t(8 * count)
	if output == nil || capacity < required { return -2 }
	for i := 0; i < count; i += 1 { write_i64_le(output, 8 * i, words[i]) }
	return i64(required)
}
