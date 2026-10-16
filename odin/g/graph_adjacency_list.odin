package graph_adjacency_list

import "core:c"

find_vertex :: proc "contextless" (order: ^[32]int, count, value: int) -> int {
	for i := 0; i < count; i += 1 {
		if order[i] == value { return i }
	}
	return -1
}

find_neighbor :: proc "contextless" (rows: ^[32][34]int, degree: ^[32]int, from, to: int) -> int {
	for i := 0; i < degree[from]; i += 1 {
		if rows[from][i] == to { return i }
	}
	return -1
}

erase_neighbor :: proc "contextless" (rows: ^[32][34]int, degree: ^[32]int, from, at: int) {
	for i := at; i + 1 < degree[from]; i += 1 {
		rows[from][i] = rows[from][i + 1]
	}
	degree[from] -= 1
}

put_i64_le :: proc "contextless" (output: [^]u8, word: usize, value: i64) {
	bits := u64(value)
	for byte: usize = 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8((bits >> (byte*8)) & 255)
	}
}

@(export)
graph_adjacency_list :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 { return -1 }
	directed := input[0]
	initial_count := input[1]
	if (directed != 0 && directed != 1) || initial_count < 0 || initial_count > 32 || length < c.size_t(4+initial_count) { return -1 }
	var order: [32]int
	var rows: [32][34]int
	var degree: [32]int
	count := int(initial_count)
	cursor := 2
	for i := 0; i < count; i += 1 {
		vertex := input[cursor]
		cursor += 1
		if vertex < 0 || vertex >= 32 || find_vertex(&order, i, int(vertex)) >= 0 { return -1 }
		order[i] = int(vertex)
	}
	edge_count := input[cursor]
	cursor += 1
	if edge_count < 0 || edge_count > 1024 || length < c.size_t(cursor+2*edge_count+1) { return -1 }
	for i: i64 = 0; i < edge_count; i += 1 {
		from_value := input[cursor]
		to_value := input[cursor+1]
		cursor += 2
		if from_value < 0 || from_value >= 32 || to_value < 0 || to_value >= 32 { return -1 }
		from := int(from_value)
		to := int(to_value)
		if find_vertex(&order, count, from) < 0 || find_vertex(&order, count, to) < 0 || find_neighbor(&rows, &degree, from, to) >= 0 { return -1 }
		rows[from][degree[from]] = to
		degree[from] += 1
		if directed == 0 {
			rows[to][degree[to]] = from
			degree[to] += 1
		}
	}
	operation_count := input[cursor]
	cursor += 1
	if operation_count < 0 || operation_count > 64 || length != c.size_t(cursor+3*operation_count) { return -1 }
	var results: [64]int
	for index := 0; index < int(operation_count); index += 1 {
		op := input[cursor]
		a_value := input[cursor+1]
		b_value := input[cursor+2]
		cursor += 3
		if op == 0 {
			if a_value < 0 || a_value >= 32 || b_value != 0 || count >= 32 || find_vertex(&order, count, int(a_value)) >= 0 { return -1 }
			order[count] = int(a_value)
			degree[int(a_value)] = 0
			count += 1
			results[index] = 1
		} else if op == 1 {
			if a_value < 0 || a_value >= 32 || b_value != 0 { return -1 }
			vertex := int(a_value)
			at := find_vertex(&order, count, vertex)
			if at < 0 { return -1 }
			if directed == 1 {
				for u := 0; u < count; u += 1 {
					source := order[u]
					edge := find_neighbor(&rows, &degree, source, vertex)
					for edge >= 0 {
						erase_neighbor(&rows, &degree, source, edge)
						edge = find_neighbor(&rows, &degree, source, vertex)
					}
				}
			} else {
				for degree[vertex] > 0 {
					neighbor := rows[vertex][degree[vertex]-1]
					degree[vertex] -= 1
					if neighbor != vertex {
						edge := find_neighbor(&rows, &degree, neighbor, vertex)
						if edge >= 0 { erase_neighbor(&rows, &degree, neighbor, edge) }
					}
				}
			}
			for j := at; j+1 < count; j += 1 { order[j] = order[j+1] }
			degree[vertex] = 0
			count -= 1
			results[index] = 1
		} else if op == 2 || op == 3 || op == 5 {
			if a_value < 0 || a_value >= 32 || b_value < 0 || b_value >= 32 { return -1 }
			from := int(a_value)
			to := int(b_value)
			if find_vertex(&order, count, from) < 0 || find_vertex(&order, count, to) < 0 { return -1 }
			edge := find_neighbor(&rows, &degree, from, to)
			if op == 5 {
				if edge >= 0 { results[index] = 1 }
			} else if op == 2 {
				if edge >= 0 || degree[from] >= 34 || (directed == 0 && degree[to] >= 34) { return -1 }
				rows[from][degree[from]] = to
				degree[from] += 1
				if directed == 0 {
					rows[to][degree[to]] = from
					degree[to] += 1
				}
				results[index] = 1
			} else {
				if edge < 0 { return -1 }
				erase_neighbor(&rows, &degree, from, edge)
				if directed == 0 {
					reverse := find_neighbor(&rows, &degree, to, from)
					if reverse < 0 { return -1 }
					erase_neighbor(&rows, &degree, to, reverse)
				}
				results[index] = 1
			}
		} else if op == 4 {
			if a_value < 0 || a_value >= 32 || b_value != 0 { return -1 }
			if find_vertex(&order, count, int(a_value)) >= 0 { results[index] = 1 }
		} else if op == 6 {
			if a_value != 0 || b_value != 0 { return -1 }
			count = 0
			degree = [32]int{}
			results[index] = 1
		} else { return -1 }
	}
	words := 2 + int(operation_count)
	for i := 0; i < count; i += 1 { words += 2 + degree[order[i]] }
	if output == nil || capacity < c.size_t(words*8) { return -2 }
	word := usize(0)
	put_i64_le(output, word, operation_count)
	word += 1
	for i := 0; i < int(operation_count); i += 1 {
		put_i64_le(output, word, i64(results[i]))
		word += 1
	}
	put_i64_le(output, word, i64(count))
	word += 1
	for i := 0; i < count; i += 1 {
		vertex := order[i]
		put_i64_le(output, word, i64(vertex))
		word += 1
		put_i64_le(output, word, i64(degree[vertex]))
		word += 1
		for j := 0; j < degree[vertex]; j += 1 {
			put_i64_le(output, word, i64(rows[vertex][j]))
			word += 1
		}
	}
	return i64(words*8)
}
