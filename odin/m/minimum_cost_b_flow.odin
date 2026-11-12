package minimum_cost_b_flow

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 10
MAX_ARCS :: 2 * MAX_EDGES + 2 * MAX_VERTICES
MAX_NODES :: MAX_VERTICES + 2
MAX_INPUT_LENGTH :: 2 + MAX_VERTICES + 5 * MAX_EDGES + 1
MAX_OUTPUT_WORDS :: 2 + MAX_VERTICES + MAX_EDGES

Residual_Graph :: struct {
	from: [MAX_ARCS]int,
	to: [MAX_ARCS]int,
	reverse: [MAX_ARCS]int,
	capacity: [MAX_ARCS]i64,
	cost: [MAX_ARCS]i64,
	arc_count: int,
	original_arc_count: int,
}

add_edge :: proc "contextless" (graph: ^Residual_Graph, from, to: int, capacity, cost: i64) -> int {
	forward := graph.arc_count
	backward := forward + 1
	graph.arc_count += 2
	graph.from[forward] = from
	graph.to[forward] = to
	graph.reverse[forward] = backward
	graph.capacity[forward] = capacity
	graph.cost[forward] = cost
	graph.from[backward] = to
	graph.to[backward] = from
	graph.reverse[backward] = forward
	graph.capacity[backward] = 0
	graph.cost[backward] = -cost
	return forward
}

feasible_flow :: proc "contextless" (graph: ^Residual_Graph, vertex_count: int, required_flow: i64) -> bool {
	super_source, super_sink := vertex_count, vertex_count + 1
	sent: i64 = 0
	for sent < required_flow {
		parent: [MAX_NODES]int
		seen: [MAX_NODES]bool
		queue: [MAX_NODES]int
		for vertex := 0; vertex < MAX_NODES; vertex += 1 { parent[vertex] = -1 }
		queue_head, queue_length := 0, 0
		seen[super_source] = true
		queue[queue_length] = super_source
		queue_length += 1
		for queue_head < queue_length {
			vertex := queue[queue_head]
			queue_head += 1
			for edge := 0; edge < graph.arc_count; edge += 1 {
				neighbor := graph.to[edge]
				if graph.from[edge] == vertex && graph.capacity[edge] > 0 && !seen[neighbor] {
					seen[neighbor] = true
					parent[neighbor] = edge
					queue[queue_length] = neighbor
					queue_length += 1
				}
			}
		}
		if !seen[super_sink] do return false
		amount := required_flow - sent
		for vertex := super_sink; vertex != super_source; vertex = graph.from[parent[vertex]] {
			if amount > graph.capacity[parent[vertex]] do amount = graph.capacity[parent[vertex]]
		}
		for vertex := super_sink; vertex != super_source; vertex = graph.from[parent[vertex]] {
			edge := parent[vertex]
			graph.capacity[edge] -= amount
			graph.capacity[graph.reverse[edge]] += amount
		}
		sent += amount
	}
	return true
}

cancel_negative_cycles :: proc "contextless" (graph: ^Residual_Graph, vertex_count: int) -> bool {
	if vertex_count == 0 do return true
	for {
		var distance: [MAX_VERTICES]i64
		parent: [MAX_VERTICES]int
		for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { parent[vertex] = -1 }
		changed_vertex := -1
		for pass := 0; pass < vertex_count; pass += 1 {
			changed_vertex = -1
			for edge := 0; edge < graph.original_arc_count; edge += 1 {
				from, to := graph.from[edge], graph.to[edge]
				if graph.capacity[edge] > 0 && distance[to] > distance[from] + graph.cost[edge] {
					distance[to] = distance[from] + graph.cost[edge]
					parent[to] = edge
					changed_vertex = to
				}
			}
			if changed_vertex == -1 do break
		}
		if changed_vertex == -1 do return true
		on_cycle := changed_vertex
		for step := 0; step < vertex_count; step += 1 {
			edge := parent[on_cycle]
			if edge < 0 do return false
			on_cycle = graph.from[edge]
		}
		amount := i64(1) << 60
		vertex := on_cycle
		for {
			edge := parent[vertex]
			if edge < 0 do return false
			if amount > graph.capacity[edge] do amount = graph.capacity[edge]
			vertex = graph.from[edge]
			if vertex == on_cycle do break
		}
		vertex = on_cycle
		for {
			edge := parent[vertex]
			graph.capacity[edge] -= amount
			graph.capacity[graph.reverse[edge]] += amount
			vertex = graph.from[edge]
			if vertex == on_cycle do break
		}
	}
}

solve :: proc "contextless" (n, m: int, input: [^]i64, words: ^[MAX_OUTPUT_WORDS]i64) -> bool {
	edge_offset := 2 + n
	required: [MAX_VERTICES]i64
	for vertex := 0; vertex < n; vertex += 1 { required[vertex] = input[2 + vertex] }
	for edge := 0; edge < m; edge += 1 {
		offset := edge_offset + 5 * edge
		from, to, lower := int(input[offset]), int(input[offset + 1]), input[offset + 2]
		required[from] -= lower
		required[to] += lower
	}
	var sum, required_flow: i64
	for vertex := 0; vertex < n; vertex += 1 {
		sum += required[vertex]
		if required[vertex] > 0 do required_flow += required[vertex]
	}
	if sum != 0 do return false
	graph := Residual_Graph{}
	for edge := 0; edge < m; edge += 1 {
		offset := edge_offset + 5 * edge
		add_edge(&graph, int(input[offset]), int(input[offset + 1]),
			input[offset + 3] - input[offset + 2], input[offset + 4])
	}
	graph.original_arc_count = graph.arc_count
	for vertex := 0; vertex < n; vertex += 1 {
		if required[vertex] > 0 do add_edge(&graph, n, vertex, required[vertex], 0)
		else if required[vertex] < 0 do add_edge(&graph, vertex, n + 1, -required[vertex], 0)
	}
	if !feasible_flow(&graph, n, required_flow) || !cancel_negative_cycles(&graph, n) do return false
	potential: [MAX_VERTICES]i64
	if n > 1 {
		for _pass := 0; _pass < n - 1; _pass += 1 {
			changed := false
			for edge := 0; edge < graph.original_arc_count; edge += 1 {
				from, to := graph.from[edge], graph.to[edge]
				if graph.capacity[edge] > 0 && potential[to] > potential[from] + graph.cost[edge] {
					potential[to] = potential[from] + graph.cost[edge]
					changed = true
				}
			}
			if !changed do break
		}
	}
	words[0] = 1
	words[1] = 0
	for vertex := 0; vertex < n; vertex += 1 { words[2 + vertex] = potential[vertex] }
	for edge := 0; edge < m; edge += 1 {
		offset := edge_offset + 5 * edge
		flow := input[offset + 3] - graph.capacity[2 * edge]
		words[2 + n + edge] = flow
		words[1] += flow * input[offset + 4]
	}
	return true
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
minimum_cost_b_flow :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	raw_n, raw_m := input[0], input[1]
	if raw_n < 0 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_EDGES do return -1
	n, m := int(raw_n), int(raw_m)
	if int(length) != 2 + n + 5 * m do return -1
	for vertex := 0; vertex < n; vertex += 1 {
		if input[2 + vertex] < -5 || input[2 + vertex] > 5 do return -1
	}
	edge_offset := 2 + n
	for edge := 0; edge < m; edge += 1 {
		offset := edge_offset + 5 * edge
		from, to := input[offset], input[offset + 1]
		lower, upper, cost := input[offset + 2], input[offset + 3], input[offset + 4]
		if from < 0 || from >= raw_n || to < 0 || to >= raw_n || lower < -3 || upper > 3 ||
			lower > upper || upper - lower > 2 || cost < -4 || cost > 4 do return -1
	}
	output_words := 2 + n + m
	output_bytes := 8 * output_words
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	words: [MAX_OUTPUT_WORDS]i64
	if !solve(n, m, input, &words) {
		for word := 0; word < output_words; word += 1 { words[word] = 0 }
	}
	for word := 0; word < output_words; word += 1 { store_i64_le(output, word * 8, words[word]) }
	return i64(output_bytes)
}
