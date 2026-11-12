module minimum_cost_b_flow

const max_vertices = 8
const max_edges = 10
const max_arcs = 2 * max_edges + 2 * max_vertices
const max_nodes = max_vertices + 2
const max_input_length = 2 + max_vertices + 5 * max_edges + 1

struct Residual_Graph {
mut:
	from [max_arcs]int
	to [max_arcs]int
	reverse [max_arcs]int
	capacity [max_arcs]i64
	cost [max_arcs]i64
	arc_count int
	original_arc_count int
}

fn add_edge(mut graph Residual_Graph, from int, to int, capacity i64, cost i64) {
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
}

fn feasible_flow(mut graph Residual_Graph, vertex_count int, required_flow i64) bool {
	super_source, super_sink := vertex_count, vertex_count + 1
	mut sent := i64(0)
	for sent < required_flow {
		mut parent := [max_nodes]int{}
		mut seen := [max_nodes]bool{}
		mut queue := [max_nodes]int{}
		for vertex in 0 .. max_nodes { parent[vertex] = -1 }
		mut head := 0
		mut length := 0
		seen[super_source] = true
		queue[length] = super_source
		length++
		for head < length {
			vertex := queue[head]
			head++
			for edge in 0 .. graph.arc_count {
				neighbor := graph.to[edge]
				if graph.from[edge] == vertex && graph.capacity[edge] > 0 && !seen[neighbor] {
					seen[neighbor] = true
					parent[neighbor] = edge
					queue[length] = neighbor
					length++
				}
			}
		}
		if !seen[super_sink] { return false }
		mut amount := required_flow - sent
		mut vertex := super_sink
		for vertex != super_source {
			edge := parent[vertex]
			if amount > graph.capacity[edge] { amount = graph.capacity[edge] }
			vertex = graph.from[edge]
		}
		vertex = super_sink
		for vertex != super_source {
			edge := parent[vertex]
			graph.capacity[edge] -= amount
			graph.capacity[graph.reverse[edge]] += amount
			vertex = graph.from[edge]
		}
		sent += amount
	}
	return true
}

fn cancel_negative_cycles(mut graph Residual_Graph, vertex_count int) bool {
	if vertex_count == 0 { return true }
	for {
		mut distance := [max_vertices]i64{}
		mut parent := [max_vertices]int{}
		for vertex in 0 .. max_vertices { parent[vertex] = -1 }
		mut changed_vertex := -1
		for _ in 0 .. vertex_count {
			changed_vertex = -1
			for edge in 0 .. graph.original_arc_count {
				from, to := graph.from[edge], graph.to[edge]
				if graph.capacity[edge] > 0 && distance[to] > distance[from] + graph.cost[edge] {
					distance[to] = distance[from] + graph.cost[edge]
					parent[to] = edge
					changed_vertex = to
				}
			}
			if changed_vertex == -1 { break }
		}
		if changed_vertex == -1 { return true }
		mut on_cycle := changed_vertex
		for _ in 0 .. vertex_count {
			edge := parent[on_cycle]
			if edge < 0 { return false }
			on_cycle = graph.from[edge]
		}
		mut amount := i64(1) << 60
		mut vertex := on_cycle
		for {
			edge := parent[vertex]
			if edge < 0 { return false }
			if amount > graph.capacity[edge] { amount = graph.capacity[edge] }
			vertex = graph.from[edge]
			if vertex == on_cycle { break }
		}
		vertex = on_cycle
		for {
			edge := parent[vertex]
			graph.capacity[edge] -= amount
			graph.capacity[graph.reverse[edge]] += amount
			vertex = graph.from[edge]
			if vertex == on_cycle { break }
		}
	}
}

fn solve(n int, m int, input &i64, mut words [20]i64) bool {
	unsafe {
	edge_offset := 2 + n
	mut required := [max_vertices]i64{}
	for vertex in 0 .. n { required[vertex] = input[2 + vertex] }
	for edge in 0 .. m {
		offset := edge_offset + 5 * edge
		from, to, lower := int(input[offset]), int(input[offset + 1]), input[offset + 2]
		required[from] -= lower
		required[to] += lower
	}
	mut sum := i64(0)
	mut required_flow := i64(0)
	for vertex in 0 .. n {
		sum += required[vertex]
		if required[vertex] > 0 { required_flow += required[vertex] }
	}
	if sum != 0 { return false }
	mut graph := Residual_Graph{}
	for edge in 0 .. m {
		offset := edge_offset + 5 * edge
		add_edge(mut graph, int(input[offset]), int(input[offset + 1]),
			input[offset + 3] - input[offset + 2], input[offset + 4])
	}
	graph.original_arc_count = graph.arc_count
	for vertex in 0 .. n {
		if required[vertex] > 0 { add_edge(mut graph, n, vertex, required[vertex], 0) }
		else if required[vertex] < 0 { add_edge(mut graph, vertex, n + 1, -required[vertex], 0) }
	}
	if !feasible_flow(mut graph, n, required_flow) || !cancel_negative_cycles(mut graph, n) { return false }
	mut potential := [max_vertices]i64{}
	passes := if n > 0 { n - 1 } else { 0 }
	for _ in 0 .. passes {
		mut changed := false
		for edge in 0 .. graph.original_arc_count {
			from, to := graph.from[edge], graph.to[edge]
			if graph.capacity[edge] > 0 && potential[to] > potential[from] + graph.cost[edge] {
				potential[to] = potential[from] + graph.cost[edge]
				changed = true
			}
		}
		if !changed { break }
	}
	words[0] = 1
	words[1] = 0
	for vertex in 0 .. n { words[2 + vertex] = potential[vertex] }
	for edge in 0 .. m {
		offset := edge_offset + 5 * edge
		flow := input[offset + 3] - graph.capacity[2 * edge]
		words[2 + n + edge] = flow
		words[1] += flow * input[offset + 4]
	}
	return true
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'minimum_cost_b_flow']
pub fn minimum_cost_b_flow(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		raw_n, raw_m := input[0], input[1]
		if raw_n < 0 || raw_n > max_vertices || raw_m < 0 || raw_m > max_edges { return -1 }
		n, m := int(raw_n), int(raw_m)
		if int(length) != 2 + n + 5 * m { return -1 }
		for vertex in 0 .. n { if input[2 + vertex] < -5 || input[2 + vertex] > 5 { return -1 } }
		edge_offset := 2 + n
		for edge in 0 .. m {
			offset := edge_offset + 5 * edge
			from, to := input[offset], input[offset + 1]
			lower, upper, cost := input[offset + 2], input[offset + 3], input[offset + 4]
			if from < 0 || from >= raw_n || to < 0 || to >= raw_n || lower < -3 || upper > 3 ||
				lower > upper || upper - lower > 2 || cost < -4 || cost > 4 { return -1 }
		}
		output_bytes := 8 * (2 + n + m)
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut words := [20]i64{}
		if !solve(n, m, input, mut words) { words = [20]i64{} }
		for word in 0 .. 2 + n + m { store_i64_le(mut output, word * 8, words[word]) }
		return i64(output_bytes)
	}
}
