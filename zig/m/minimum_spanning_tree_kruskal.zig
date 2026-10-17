const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 4096;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES;

fn edgeLess(input: [*]const i64, left: usize, right: usize) bool {
    const left_weight = input[2 + 3 * left + 2];
    const right_weight = input[2 + 3 * right + 2];
    return left_weight < right_weight or (left_weight == right_weight and left < right);
}

fn siftDown(input: [*]const i64, order: [*]usize, root_start: usize, ending: usize) void {
    var root = root_start;
    while (root * 2 + 1 < ending) {
        var child = root * 2 + 1;
        if (child + 1 < ending and edgeLess(input, order[child], order[child + 1])) child += 1;
        if (!edgeLess(input, order[root], order[child])) break;
        const temporary = order[root];
        order[root] = order[child];
        order[child] = temporary;
        root = child;
    }
}

fn heapSort(input: [*]const i64, order: [*]usize, count: usize) void {
    var start = count / 2;
    while (start > 0) {
        start -= 1;
        siftDown(input, order, start, count);
    }
    var ending = count;
    while (ending > 1) {
        ending -= 1;
        const temporary = order[0];
        order[0] = order[ending];
        order[ending] = temporary;
        siftDown(input, order, 0, ending);
    }
}

fn findRoot(parent: [*]usize, node_start: usize) usize {
    var node = node_start;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_spanning_tree_kruskal(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const raw_vertices = values[0];
    const raw_edges = values[1];
    if (raw_vertices < 0 or raw_vertices > 64 or
        raw_edges < 0 or raw_edges > 4096) return -1;
    const vertex_count: usize = @intCast(raw_vertices);
    const edge_count: usize = @intCast(raw_edges);
    if (length != 2 + 3 * edge_count) return -1;

    var order: [MAX_EDGES]usize = undefined;
    for (0..edge_count) |index| {
        const offset = 2 + 3 * index;
        const u = values[offset];
        const v = values[offset + 1];
        if (u < 0 or u >= raw_vertices or v < 0 or v >= raw_vertices) return -1;
        order[index] = index;
    }
    heapSort(values, &order[0], edge_count);

    var parent: [MAX_VERTICES]usize = undefined;
    for (0..vertex_count) |vertex| parent[vertex] = vertex;
    var accepted: [MAX_VERTICES]usize = undefined;
    var accepted_count: usize = 0;
    for (0..edge_count) |index| {
        const edge_index = order[index];
        const offset = 2 + 3 * edge_index;
        const left_root = findRoot(&parent[0], @intCast(values[offset]));
        const right_root = findRoot(&parent[0], @intCast(values[offset + 1]));
        if (left_root != right_root) {
            accepted[accepted_count] = edge_index;
            accepted_count += 1;
            parent[left_root] = right_root;
        }
    }

    const byte_count = accepted_count * 24;
    if (output == null or capacity < byte_count) return -2;
    const result = output.?;
    for (0..accepted_count) |index| {
        const input_offset = 2 + 3 * accepted[index];
        const output_offset = index * 24;
        putI64Le(result, output_offset, values[input_offset]);
        putI64Le(result, output_offset + 8, values[input_offset + 1]);
        putI64Le(result, output_offset + 16, values[input_offset + 2]);
    }
    return @intCast(byte_count);
}
