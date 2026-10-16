module graph_adjacency_list

const max_vertices = 32
const max_neighbors = 34
const max_operations = 64

fn find_vertex(order [32]int, count int, value int) int {
	for i in 0 .. count { if order[i] == value { return i } }
	return -1
}

fn find_neighbor(rows [32][34]int, degree [32]int, from int, to int) int {
	for i in 0 .. degree[from] { if rows[from][i] == to { return i } }
	return -1
}

fn erase_neighbor(mut rows [32][34]int, mut degree [32]int, from int, at int) {
	for i in at .. degree[from] - 1 { rows[from][i] = rows[from][i + 1] }
	degree[from]--
}

fn valid_id(value i64) bool { return value >= 0 && value < max_vertices }

fn put_i64_le(output &u8, word usize, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + usize(byte)] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'graph_adjacency_list']
pub fn graph_adjacency_list(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	unsafe {
		directed_value := input[0]
		initial_count := input[1]
		if (directed_value != 0 && directed_value != 1) || initial_count < 0 || initial_count > 32 || length < usize(4 + initial_count) { return -1 }
		mut order := [32]int{}
		mut rows := [32][34]int{}
		mut degree := [32]int{}
		mut count := int(initial_count)
		for i in 0 .. count {
			value := input[2 + i]
			if !valid_id(value) { return -1 }
			for j in 0 .. i { if order[j] == int(value) { return -1 } }
			order[i] = int(value)
		}
		mut cursor := 2 + count
		edge_count := input[cursor]
		cursor++
		if edge_count < 0 || edge_count > 1024 || length < usize(cursor + 2 * edge_count + 1) { return -1 }
		for _ in 0 .. int(edge_count) {
			from_value := input[cursor]
			to_value := input[cursor + 1]
			cursor += 2
			if !valid_id(from_value) || !valid_id(to_value) { return -1 }
			from := int(from_value)
			to := int(to_value)
			if find_vertex(order, count, from) < 0 || find_vertex(order, count, to) < 0 || find_neighbor(rows, degree, from, to) >= 0 { return -1 }
			rows[from][degree[from]] = to
			degree[from]++
			if directed_value == 0 { rows[to][degree[to]] = from; degree[to]++ }
		}
		operation_count := input[cursor]
		cursor++
		if operation_count < 0 || operation_count > 64 || length != usize(cursor + 3 * operation_count) { return -1 }
		mut results := [64]int{}
		for operation_index in 0 .. int(operation_count) {
			op := input[cursor]
			a_value := input[cursor + 1]
			b_value := input[cursor + 2]
			cursor += 3
			if op == 0 {
				if !valid_id(a_value) || b_value != 0 || find_vertex(order, count, int(a_value)) >= 0 || count >= 32 { return -1 }
				order[count] = int(a_value); count++; degree[int(a_value)] = 0; results[operation_index] = 1
			} else if op == 1 {
				if !valid_id(a_value) || b_value != 0 { return -1 }
				vertex := int(a_value)
				at := find_vertex(order, count, vertex)
				if at < 0 { return -1 }
				if directed_value == 1 {
					for u in 0 .. count {
						source := order[u]
						mut edge := find_neighbor(rows, degree, source, vertex)
						for edge >= 0 { erase_neighbor(mut rows, mut degree, source, edge); edge = find_neighbor(rows, degree, source, vertex) }
					}
				} else {
					for degree[vertex] > 0 {
						neighbor := rows[vertex][degree[vertex] - 1]
						degree[vertex]--
						if neighbor != vertex { edge := find_neighbor(rows, degree, neighbor, vertex); if edge >= 0 { erase_neighbor(mut rows, mut degree, neighbor, edge) } }
					}
				}
				for j in at .. count - 1 { order[j] = order[j + 1] }
				degree[vertex] = 0; count--; results[operation_index] = 1
			} else if op == 2 || op == 3 || op == 5 {
				if !valid_id(a_value) || !valid_id(b_value) { return -1 }
				from := int(a_value); to := int(b_value)
				if find_vertex(order, count, from) < 0 || find_vertex(order, count, to) < 0 { return -1 }
				edge := find_neighbor(rows, degree, from, to)
				if op == 5 { results[operation_index] = if edge >= 0 { 1 } else { 0 }
				} else if op == 2 {
					if edge >= 0 || degree[from] >= 34 || (directed_value == 0 && degree[to] >= 34) { return -1 }
					rows[from][degree[from]] = to; degree[from]++
					if directed_value == 0 { rows[to][degree[to]] = from; degree[to]++ }
					results[operation_index] = 1
				} else {
					if edge < 0 { return -1 }
					erase_neighbor(mut rows, mut degree, from, edge)
					if directed_value == 0 { reverse := find_neighbor(rows, degree, to, from); if reverse < 0 { return -1 }; erase_neighbor(mut rows, mut degree, to, reverse) }
					results[operation_index] = 1
				}
			} else if op == 4 {
				if !valid_id(a_value) || b_value != 0 { return -1 }
				results[operation_index] = if find_vertex(order, count, int(a_value)) >= 0 { 1 } else { 0 }
			} else if op == 6 {
				if a_value != 0 || b_value != 0 { return -1 }
				count = 0
				for i in 0 .. 32 { degree[i] = 0 }
				results[operation_index] = 1
			} else { return -1 }
		}
		mut words := 2 + int(operation_count)
		for i in 0 .. count { words += 2 + degree[order[i]] }
		if unsafe { output == nil } || capacity < usize(words * 8) { return -2 }
		mut word := usize(0)
		put_i64_le(output, word, operation_count); word++
		for i in 0 .. int(operation_count) { put_i64_le(output, word, results[i]); word++ }
		put_i64_le(output, word, count); word++
		for i in 0 .. count {
			vertex := order[i]
			put_i64_le(output, word, vertex); word++
			put_i64_le(output, word, degree[vertex]); word++
			for j in 0 .. degree[vertex] { put_i64_le(output, word, rows[vertex][j]); word++ }
		}
		return i64(words * 8)
	}
}
