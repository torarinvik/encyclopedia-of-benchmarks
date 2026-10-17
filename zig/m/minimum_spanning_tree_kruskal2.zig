const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_INPUT_WORDS: usize = 194;
const MAX_OUTPUT_WORDS: usize = 1 + 3 * (MAX_VERTICES - 1);

const Edge = struct { u: i32, v: i32, weight: i32 };

fn findRoot(parent: *[MAX_VERTICES]i32, node: i32) i32 {
    var current = node;
    while (parent[@intCast(current)] != current) {
        const index: usize = @intCast(current);
        parent[index] = parent[@intCast(parent[index])];
        current = parent[index];
    }
    return current;
}

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_spanning_tree_kruskal2(input_opt: ?[*]const i32, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const vertex_count = input[0];
    const edge_count = input[1];
    if (vertex_count < 1 or vertex_count > @as(i32, @intCast(MAX_VERTICES)) or
        edge_count < 0 or edge_count > @as(i32, @intCast(MAX_EDGES)) or
        length != 2 + 3 * @as(usize, @intCast(edge_count))) return -1;

    var input_edges: [MAX_EDGES]Edge = undefined;
    var seen = [_][MAX_VERTICES]bool{[_]bool{false} ** MAX_VERTICES} ** MAX_VERTICES;
    var pos: usize = 2;
    for (0..@intCast(edge_count)) |i| {
        const u = input[pos];
        const v = input[pos + 1];
        const weight = input[pos + 2];
        pos += 3;
        if (u < 0 or v <= u or v >= vertex_count or seen[@intCast(u)][@intCast(v)]) return -1;
        seen[@intCast(u)][@intCast(v)] = true;
        input_edges[i] = .{ .u = u, .v = v, .weight = weight };
    }

    var visited = [_]bool{false} ** MAX_VERTICES;
    var stack: [MAX_VERTICES]usize = undefined;
    var stack_size: usize = 1;
    var reached: usize = 0;
    stack[0] = 0;
    visited[0] = true;
    while (stack_size > 0) {
        stack_size -= 1;
        const node = stack[stack_size];
        reached += 1;
        for (0..@intCast(vertex_count)) |neighbor| {
            if ((seen[node][neighbor] or seen[neighbor][node]) and !visited[neighbor]) {
                visited[neighbor] = true;
                stack[stack_size] = neighbor;
                stack_size += 1;
            }
        }
    }
    if (reached != @as(usize, @intCast(vertex_count))) return -1;

    var ordered: [MAX_EDGES]Edge = undefined;
    var ordered_count: usize = 0;
    for (0..@intCast(vertex_count)) |u| {
        for (0..@intCast(edge_count)) |i| {
            if (input_edges[i].u == @as(i32, @intCast(u))) {
                ordered[ordered_count] = input_edges[i];
                ordered_count += 1;
            }
        }
    }
    for (1..ordered_count) |i| {
        const key = ordered[i];
        var j = i;
        while (j > 0 and ordered[j - 1].weight > key.weight) : (j -= 1) {
            ordered[j] = ordered[j - 1];
        }
        ordered[j] = key;
    }

    var parent = [_]i32{0} ** MAX_VERTICES;
    var rank = [_]i32{0} ** MAX_VERTICES;
    for (0..@intCast(vertex_count)) |i| parent[i] = @intCast(i);
    var words: [MAX_OUTPUT_WORDS]i32 = undefined;
    var word_count: usize = 1;
    var accepted: usize = 0;
    for (0..ordered_count) |i| {
        if (accepted == @as(usize, @intCast(vertex_count - 1))) break;
        const edge = ordered[i];
        const root_u = findRoot(&parent, edge.u);
        const root_v = findRoot(&parent, edge.v);
        if (root_u == root_v) continue;
        if (rank[@intCast(root_u)] < rank[@intCast(root_v)]) parent[@intCast(root_u)] = root_v
        else if (rank[@intCast(root_u)] > rank[@intCast(root_v)]) parent[@intCast(root_v)] = root_u
        else {
            parent[@intCast(root_u)] = root_v;
            rank[@intCast(root_v)] += 1;
        }
        words[word_count] = edge.u;
        words[word_count + 1] = edge.v;
        words[word_count + 2] = edge.weight;
        word_count += 3;
        accepted += 1;
    }
    if (accepted != @as(usize, @intCast(vertex_count - 1))) return -1;
    words[0] = @intCast(accepted);
    const bytes = word_count * 4;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_WORDS * 4]u8 = undefined;
    for (0..word_count) |i| putI32Le(&buffer, i * 4, words[i]);
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
