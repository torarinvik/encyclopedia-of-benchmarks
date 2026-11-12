module strong_orientation

const max_vertices = 64
const max_edges = 128
const max_arcs = 2 * max_edges
const max_input_length = 2 + 2 * max_edges + 1

struct Graph {
mut:
	head [max_vertices]int
	tail [max_vertices]int
	to [max_arcs]int
	next [max_arcs]int
	arc_edge [max_arcs]int
	edge_u [max_edges]int
	edge_used [max_edges]bool
	direction [max_edges]int
	discovery [max_vertices]int
	low [max_vertices]int
	timer int
	bridges int
}

fn append_arc(mut state Graph, from int, target int, edge int, mut arc_count int) {
	arc := arc_count
	arc_count++
	state.to[arc] = target
	state.arc_edge[arc] = edge
	state.next[arc] = -1
	if state.head[from] == -1 { state.head[from] = arc }
	else { state.next[state.tail[from]] = arc }
	state.tail[from] = arc
}

fn visit(mut state Graph, vertex int) {
	state.discovery[vertex] = state.timer
	state.low[vertex] = state.timer
	state.timer++
	mut arc := state.head[vertex]
	for arc != -1 {
		next_arc := state.next[arc]
		edge := state.arc_edge[arc]
		if !state.edge_used[edge] {
			state.edge_used[edge] = true
			state.direction[edge] = if vertex == state.edge_u[edge] { 1 } else { -1 }
			neighbor := state.to[arc]
			if state.discovery[neighbor] == -1 {
				visit(mut state, neighbor)
				if state.low[neighbor] < state.low[vertex] { state.low[vertex] = state.low[neighbor] }
				if state.low[neighbor] > state.discovery[vertex] { state.bridges++ }
			} else if state.discovery[neighbor] < state.low[vertex] {
				state.low[vertex] = state.discovery[neighbor]
			}
		}
		arc = next_arc
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'strong_orientation']
pub fn strong_orientation(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		raw_vertices, raw_edges := input[0], input[1]
		if raw_vertices < 1 || raw_vertices > max_vertices || raw_edges < 0 || raw_edges > max_edges { return -1 }
		vertex_count, edge_count := int(raw_vertices), int(raw_edges)
		if int(length) != 2 + 2 * edge_count { return -1 }
		for edge in 0 .. edge_count {
			left, right := input[2 + 2 * edge], input[3 + 2 * edge]
			if left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices { return -1 }
		}
		output_bytes := 8 * (edge_count + 1)
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut state := Graph{}
		for vertex in 0 .. max_vertices {
			state.head[vertex] = -1
			state.tail[vertex] = -1
			state.discovery[vertex] = -1
		}
		mut arc_count := 0
		for edge in 0 .. edge_count {
			left, right := int(input[2 + 2 * edge]), int(input[3 + 2 * edge])
			state.edge_u[edge] = left
			append_arc(mut state, left, right, edge, mut arc_count)
			append_arc(mut state, right, left, edge, mut arc_count)
		}
		mut components := 0
		for vertex in 0 .. vertex_count {
			if state.discovery[vertex] == -1 {
				components++
				visit(mut state, vertex)
			}
		}
		store_i64_le(mut output, 0, i64(components + state.bridges))
		for edge in 0 .. edge_count {
			store_i64_le(mut output, 8 * (edge + 1), i64(state.direction[edge]))
		}
		return i64(output_bytes)
	}
}
