const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 10;
const MAX_ARCS: usize = 2 * MAX_EDGES + 2 * MAX_VERTICES;
const MAX_NODES: usize = MAX_VERTICES + 2;
const MAX_INPUT_LENGTH: usize = 2 + MAX_VERTICES + 5 * MAX_EDGES + 1;
const MAX_OUTPUT_WORDS: usize = 2 + MAX_VERTICES + MAX_EDGES;

const ResidualGraph = struct {
	from: [MAX_ARCS]i32 = [_]i32{0} ** MAX_ARCS,
	to: [MAX_ARCS]i32 = [_]i32{0} ** MAX_ARCS,
	reverse: [MAX_ARCS]i32 = [_]i32{0} ** MAX_ARCS,
	capacity: [MAX_ARCS]i64 = [_]i64{0} ** MAX_ARCS,
	cost: [MAX_ARCS]i64 = [_]i64{0} ** MAX_ARCS,
	arc_count: usize = 0,
	original_arc_count: usize = 0,

	fn addEdge(self: *ResidualGraph, from: usize, to: usize, capacity: i64, cost: i64) void {
		const forward = self.arc_count;
		const backward = forward + 1;
		self.arc_count += 2;
		self.from[forward] = @intCast(from);
		self.to[forward] = @intCast(to);
		self.reverse[forward] = @intCast(backward);
		self.capacity[forward] = capacity;
		self.cost[forward] = cost;
		self.from[backward] = @intCast(to);
		self.to[backward] = @intCast(from);
		self.reverse[backward] = @intCast(forward);
		self.capacity[backward] = 0;
		self.cost[backward] = -cost;
	}

	fn feasibleFlow(self: *ResidualGraph, vertex_count: usize, required_flow: i64) bool {
		const super_source = vertex_count;
		const super_sink = vertex_count + 1;
		var sent: i64 = 0;
		while (sent < required_flow) {
			var parent = [_]i32{-1} ** MAX_NODES;
			var seen = [_]bool{false} ** MAX_NODES;
			var queue = [_]usize{0} ** MAX_NODES;
			var head: usize = 0;
			var length: usize = 1;
			seen[super_source] = true;
			queue[0] = super_source;
			while (head < length) : (head += 1) {
				const vertex = queue[head];
				for (0..self.arc_count) |edge| {
					const neighbor: usize = @intCast(self.to[edge]);
					if (@as(usize, @intCast(self.from[edge])) == vertex and self.capacity[edge] > 0 and !seen[neighbor]) {
						seen[neighbor] = true;
						parent[neighbor] = @intCast(edge);
						queue[length] = neighbor;
						length += 1;
					}
				}
			}
			if (!seen[super_sink]) return false;
			var amount = required_flow - sent;
			var vertex = super_sink;
			while (vertex != super_source) {
				const edge: usize = @intCast(parent[vertex]);
				amount = @min(amount, self.capacity[edge]);
				vertex = @intCast(self.from[edge]);
			}
			vertex = super_sink;
			while (vertex != super_source) {
				const edge: usize = @intCast(parent[vertex]);
				self.capacity[edge] -= amount;
				const backward: usize = @intCast(self.reverse[edge]);
				self.capacity[backward] += amount;
				vertex = @intCast(self.from[edge]);
			}
			sent += amount;
		}
		return true;
	}

	fn cancelNegativeCycles(self: *ResidualGraph, vertex_count: usize) bool {
		if (vertex_count == 0) return true;
		while (true) {
			var distance = [_]i64{0} ** MAX_VERTICES;
			var parent = [_]i32{-1} ** MAX_VERTICES;
			var changed_vertex: i32 = -1;
			for (0..vertex_count) |_| {
				changed_vertex = -1;
				for (0..self.original_arc_count) |edge| {
					const from: usize = @intCast(self.from[edge]);
					const to: usize = @intCast(self.to[edge]);
					if (self.capacity[edge] > 0 and distance[to] > distance[from] + self.cost[edge]) {
						distance[to] = distance[from] + self.cost[edge];
						parent[to] = @intCast(edge);
						changed_vertex = @intCast(to);
					}
				}
				if (changed_vertex == -1) break;
			}
			if (changed_vertex == -1) return true;
			var on_cycle: usize = @intCast(changed_vertex);
			for (0..vertex_count) |_| {
				const edge: usize = @intCast(parent[on_cycle]);
				on_cycle = @intCast(self.from[edge]);
			}
			var amount: i64 = 1 << 60;
			var vertex = on_cycle;
			while (true) {
				const edge: usize = @intCast(parent[vertex]);
				amount = @min(amount, self.capacity[edge]);
				vertex = @intCast(self.from[edge]);
				if (vertex == on_cycle) break;
			}
			vertex = on_cycle;
			while (true) {
				const edge: usize = @intCast(parent[vertex]);
				self.capacity[edge] -= amount;
				const backward: usize = @intCast(self.reverse[edge]);
				self.capacity[backward] += amount;
				vertex = @intCast(self.from[edge]);
				if (vertex == on_cycle) break;
			}
		}
	}
};

fn solve(n: usize, m: usize, input: [*]const i64, words: *[MAX_OUTPUT_WORDS]i64) bool {
	const edge_offset = 2 + n;
	var required = [_]i64{0} ** MAX_VERTICES;
	for (0..n) |vertex| required[vertex] = input[2 + vertex];
	for (0..m) |edge| {
		const offset = edge_offset + 5 * edge;
		const from: usize = @intCast(input[offset]);
		const to: usize = @intCast(input[offset + 1]);
		const lower = input[offset + 2];
		required[from] -= lower;
		required[to] += lower;
	}
	var required_sum: i64 = 0;
	var required_flow: i64 = 0;
	for (0..n) |vertex| {
		required_sum += required[vertex];
		if (required[vertex] > 0) required_flow += required[vertex];
	}
	if (required_sum != 0) return false;

	var graph = ResidualGraph{};
	for (0..m) |edge| {
		const offset = edge_offset + 5 * edge;
		graph.addEdge(@intCast(input[offset]), @intCast(input[offset + 1]),
			input[offset + 3] - input[offset + 2], input[offset + 4]);
	}
	graph.original_arc_count = graph.arc_count;
	for (0..n) |vertex| {
		if (required[vertex] > 0) graph.addEdge(n, vertex, required[vertex], 0)
		else if (required[vertex] < 0) graph.addEdge(vertex, n + 1, -required[vertex], 0);
	}
	if (!graph.feasibleFlow(n, required_flow) or !graph.cancelNegativeCycles(n)) return false;

	var potential = [_]i64{0} ** MAX_VERTICES;
	if (n > 1) {
		for (0..n - 1) |_| {
			var changed = false;
			for (0..graph.original_arc_count) |edge| {
				const from: usize = @intCast(graph.from[edge]);
				const to: usize = @intCast(graph.to[edge]);
				if (graph.capacity[edge] > 0 and potential[to] > potential[from] + graph.cost[edge]) {
					potential[to] = potential[from] + graph.cost[edge];
					changed = true;
				}
			}
			if (!changed) break;
		}
	}
	words[0] = 1;
	words[1] = 0;
	for (0..n) |vertex| words[2 + vertex] = potential[vertex];
	for (0..m) |edge| {
		const offset = edge_offset + 5 * edge;
		const flow = input[offset + 3] - graph.capacity[2 * edge];
		words[2 + n + edge] = flow;
		words[1] += flow * input[offset + 4];
	}
	return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @truncate((bits >> @intCast(byte * 8)) & 0xff);
}

export fn minimum_cost_b_flow(values: ?[*]const i64, length: usize,
	output: ?[*]u8, output_capacity: usize) i64 {
	const input = values orelse return -1;
	if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
	const raw_n = input[0];
	const raw_m = input[1];
	if (raw_n < 0 or raw_n > @as(i64, @intCast(MAX_VERTICES)) or
		raw_m < 0 or raw_m > @as(i64, @intCast(MAX_EDGES))) return -1;
	const n: usize = @intCast(raw_n);
	const m: usize = @intCast(raw_m);
	if (length != 2 + n + 5 * m) return -1;
	for (0..n) |vertex| if (input[2 + vertex] < -5 or input[2 + vertex] > 5) return -1;
	const edge_offset = 2 + n;
	for (0..m) |edge| {
		const offset = edge_offset + 5 * edge;
		const from = input[offset];
		const to = input[offset + 1];
		const lower = input[offset + 2];
		const upper = input[offset + 3];
		const cost = input[offset + 4];
		if (from < 0 or from >= raw_n or to < 0 or to >= raw_n or lower < -3 or upper > 3 or
			lower > upper or upper - lower > 2 or cost < -4 or cost > 4) return -1;
	}
	const output_words = 2 + n + m;
	const output_bytes = 8 * output_words;
	const out = output orelse return -2;
	if (output_capacity < output_bytes) return -2;
	var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
	if (!solve(n, m, input, &words)) words = [_]i64{0} ** MAX_OUTPUT_WORDS;
	for (0..output_words) |word| storeI64Le(out, 8 * word, words[word]);
	return @intCast(output_bytes);
}
