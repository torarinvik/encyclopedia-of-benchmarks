const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 128;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES + 1;

const Graph = struct {
	head: [MAX_VERTICES]i32,
	tail: [MAX_VERTICES]i32,
	to: [MAX_ARCS]i32,
	next: [MAX_ARCS]i32,
	arc_edge: [MAX_ARCS]i32,
	edge_u: [MAX_EDGES]i32,
	edge_used: [MAX_EDGES]bool,
	direction: [MAX_EDGES]i32,
	discovery: [MAX_VERTICES]i32,
	low: [MAX_VERTICES]i32,
	timer: i32,
	bridges: i32,
};

fn appendArc(state: *Graph, from: i32, target: i32, edge: i32, arc_count: *usize) void {
	const arc = arc_count.*;
	arc_count.* += 1;
	const from_index: usize = @intCast(from);
	state.to[arc] = target;
	state.arc_edge[arc] = edge;
	state.next[arc] = -1;
	if (state.head[from_index] == -1) state.head[from_index] = @intCast(arc)
	else state.next[@intCast(state.tail[from_index])] = @intCast(arc);
	state.tail[from_index] = @intCast(arc);
}

fn visit(state: *Graph, vertex: i32) void {
	const vertex_index: usize = @intCast(vertex);
	state.discovery[vertex_index] = state.timer;
	state.low[vertex_index] = state.timer;
	state.timer += 1;
	var arc = state.head[vertex_index];
	while (arc != -1) {
		const arc_index: usize = @intCast(arc);
		const next_arc = state.next[arc_index];
		const edge: usize = @intCast(state.arc_edge[arc_index]);
		if (!state.edge_used[edge]) {
			state.edge_used[edge] = true;
			state.direction[edge] = if (vertex == state.edge_u[edge]) 1 else -1;
			const neighbor = state.to[arc_index];
			const neighbor_index: usize = @intCast(neighbor);
			if (state.discovery[neighbor_index] == -1) {
				visit(state, neighbor);
				if (state.low[neighbor_index] < state.low[vertex_index])
					state.low[vertex_index] = state.low[neighbor_index];
				if (state.low[neighbor_index] > state.discovery[vertex_index]) state.bridges += 1;
			} else if (state.discovery[neighbor_index] < state.low[vertex_index]) {
				state.low[vertex_index] = state.discovery[neighbor_index];
			}
		}
		arc = next_arc;
	}
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn strong_orientation(input: [*c]const i64, length: usize,
	output: [*c]u8, output_capacity: usize) i64 {
	if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
	const raw_vertices = input[0];
	const raw_edges = input[1];
	if (raw_vertices < 1 or raw_vertices > @as(i64, @intCast(MAX_VERTICES)) or
		raw_edges < 0 or raw_edges > @as(i64, @intCast(MAX_EDGES))) return -1;
	const vertex_count: usize = @intCast(raw_vertices);
	const edge_count: usize = @intCast(raw_edges);
	if (length != 2 + 2 * edge_count) return -1;
	for (0..edge_count) |edge| {
		const left = input[2 + 2 * edge];
		const right = input[3 + 2 * edge];
		if (left < 0 or right < 0 or left >= raw_vertices or right >= raw_vertices) return -1;
	}
	const output_bytes = 8 * (edge_count + 1);
	if (output == null or output_capacity < output_bytes) return -2;

	var state = Graph{
		.head = [_]i32{-1} ** MAX_VERTICES,
		.tail = [_]i32{-1} ** MAX_VERTICES,
		.to = [_]i32{0} ** MAX_ARCS,
		.next = [_]i32{-1} ** MAX_ARCS,
		.arc_edge = [_]i32{0} ** MAX_ARCS,
		.edge_u = [_]i32{0} ** MAX_EDGES,
		.edge_used = [_]bool{false} ** MAX_EDGES,
		.direction = [_]i32{0} ** MAX_EDGES,
		.discovery = [_]i32{-1} ** MAX_VERTICES,
		.low = [_]i32{0} ** MAX_VERTICES,
		.timer = 0,
		.bridges = 0,
	};
	var arc_count: usize = 0;
	for (0..edge_count) |edge| {
		const left: i32 = @intCast(input[2 + 2 * edge]);
		const right: i32 = @intCast(input[3 + 2 * edge]);
		state.edge_u[edge] = left;
		appendArc(&state, left, right, @intCast(edge), &arc_count);
		appendArc(&state, right, left, @intCast(edge), &arc_count);
	}
	var components: i32 = 0;
	for (0..vertex_count) |vertex| {
		if (state.discovery[vertex] == -1) {
			components += 1;
			visit(&state, @intCast(vertex));
		}
	}
	storeI64Le(output, 0, @intCast(components + state.bridges));
	for (0..edge_count) |edge| storeI64Le(output, 8 * (edge + 1), @intCast(state.direction[edge]));
	return @intCast(output_bytes);
}
