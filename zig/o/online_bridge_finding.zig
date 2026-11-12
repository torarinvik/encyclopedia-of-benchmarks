const std = @import("std");

const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 128;
const MAX_INPUT_LENGTH: usize = 259;

const BridgeState = struct {
	dsu_2ecc: [MAX_VERTICES]i32,
	dsu_cc: [MAX_VERTICES]i32,
	dsu_cc_size: [MAX_VERTICES]i32,
	parent: [MAX_VERTICES]i32,
	last_visit: [MAX_VERTICES]i32,
	iteration: i32,
	bridges: i32,
};

fn find2ecc(state: *BridgeState, vertex: i32) i32 {
	if (vertex == -1) return -1;
	const index: usize = @intCast(vertex);
	if (state.dsu_2ecc[index] == vertex) return vertex;
	const next = state.dsu_2ecc[index];
	state.dsu_2ecc[index] = find2ecc(state, next);
	return state.dsu_2ecc[index];
}

fn findCc(state: *BridgeState, vertex_input: i32) i32 {
	const vertex = find2ecc(state, vertex_input);
	const index: usize = @intCast(vertex);
	if (state.dsu_cc[index] == vertex) return vertex;
	const next = state.dsu_cc[index];
	state.dsu_cc[index] = findCc(state, next);
	return state.dsu_cc[index];
}

fn makeRoot(state: *BridgeState, vertex_input: i32) void {
	const root = find2ecc(state, vertex_input);
	var vertex = root;
	var child: i32 = -1;
	while (vertex != -1) {
		const index: usize = @intCast(vertex);
		const parent = state.parent[index];
		const next = find2ecc(state, parent);
		state.parent[index] = child;
		state.dsu_cc[index] = root;
		child = vertex;
		vertex = next;
	}
	state.dsu_cc_size[@intCast(root)] = state.dsu_cc_size[@intCast(child)];
}

fn mergePath(state: *BridgeState, left_input: i32, right_input: i32) void {
	state.iteration += 1;
	var path_left: [MAX_VERTICES]i32 = [_]i32{0} ** MAX_VERTICES;
	var path_right: [MAX_VERTICES]i32 = [_]i32{0} ** MAX_VERTICES;
	var left_length: usize = 0;
	var right_length: usize = 0;
	var left = left_input;
	var right = right_input;
	var lca: i32 = -1;
	while (lca == -1) {
		if (left != -1) {
			left = find2ecc(state, left);
			const index: usize = @intCast(left);
			path_left[left_length] = left;
			left_length += 1;
			if (state.last_visit[index] == state.iteration) { lca = left; break; }
			state.last_visit[index] = state.iteration;
			left = state.parent[index];
		}
		if (right != -1) {
			right = find2ecc(state, right);
			const index: usize = @intCast(right);
			path_right[right_length] = right;
			right_length += 1;
			if (state.last_visit[index] == state.iteration) { lca = right; break; }
			state.last_visit[index] = state.iteration;
			right = state.parent[index];
		}
	}
	for (path_left[0..left_length]) |vertex| {
		state.dsu_2ecc[@intCast(vertex)] = lca;
		if (vertex == lca) break;
		state.bridges -= 1;
	}
	for (path_right[0..right_length]) |vertex| {
		state.dsu_2ecc[@intCast(vertex)] = lca;
		if (vertex == lca) break;
		state.bridges -= 1;
	}
}

fn addEdge(state: *BridgeState, left_input: i32, right_input: i32) void {
	var left = find2ecc(state, left_input);
	var right = find2ecc(state, right_input);
	if (left == right) return;
	var left_cc = findCc(state, left);
	var right_cc = findCc(state, right);
	if (left_cc != right_cc) {
		state.bridges += 1;
		if (state.dsu_cc_size[@intCast(left_cc)] > state.dsu_cc_size[@intCast(right_cc)]) {
			std.mem.swap(i32, &left, &right);
			std.mem.swap(i32, &left_cc, &right_cc);
		}
		makeRoot(state, left);
		state.parent[@intCast(left)] = right;
		state.dsu_cc[@intCast(left)] = right;
		state.dsu_cc_size[@intCast(right_cc)] += state.dsu_cc_size[@intCast(left)];
	} else {
		mergePath(state, left, right);
	}
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

/// Input is [n, m, edges...]; output stores one bridge count per insertion.
export fn online_bridge_finding(values: [*c]const i64, length: usize,
	output: [*c]u8, capacity: usize) i64 {
	if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
	const raw_vertices = values[0];
	const raw_edges = values[1];
	if (raw_vertices < 1 or raw_vertices > MAX_VERTICES or raw_edges < 0 or raw_edges > MAX_EDGES) return -1;
	const vertex_count: usize = @intCast(raw_vertices);
	const edge_count: usize = @intCast(raw_edges);
	if (length != 2 + 2 * edge_count) return -1;
	for (0..edge_count) |edge| {
		const left = values[2 + 2 * edge];
		const right = values[3 + 2 * edge];
		if (left < 0 or right < 0 or left >= raw_vertices or right >= raw_vertices) return -1;
	}
	const output_bytes = edge_count * 8;
	if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;

	var state = BridgeState{
		.dsu_2ecc = [_]i32{0} ** MAX_VERTICES,
		.dsu_cc = [_]i32{0} ** MAX_VERTICES,
		.dsu_cc_size = [_]i32{0} ** MAX_VERTICES,
		.parent = [_]i32{-1} ** MAX_VERTICES,
		.last_visit = [_]i32{0} ** MAX_VERTICES,
		.iteration = 0,
		.bridges = 0,
	};
	for (0..vertex_count) |vertex| {
		state.dsu_2ecc[vertex] = @intCast(vertex);
		state.dsu_cc[vertex] = @intCast(vertex);
		state.dsu_cc_size[vertex] = 1;
	}
	for (0..edge_count) |edge| {
		addEdge(&state, @intCast(values[2 + 2 * edge]), @intCast(values[3 + 2 * edge]));
		storeI64Le(output, edge * 8, state.bridges);
	}
	return @intCast(output_bytes);
}
