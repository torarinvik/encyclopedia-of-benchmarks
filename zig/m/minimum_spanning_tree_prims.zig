const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES + 1;
const MAX_OUTPUT_WORDS: usize = 1 + 2 * (MAX_VERTICES - 1);
const MAX_OUTPUT_BYTES: usize = 4 * MAX_OUTPUT_WORDS;
const SOURCE_HEAP_SENTINEL: i64 = 9223372036854775807;

fn topToBottom(
    heap: *[MAX_VERTICES]i64,
    positions: *[MAX_VERTICES]i32,
    node_position: *[MAX_VERTICES]i32,
    size: usize,
    start: usize,
) void {
    var root = start;
    while (root * 2 + 1 < size) {
        const left = root * 2 + 1;
        const right = left + 1;
        const child = if (right >= size or heap.*[left] < heap.*[right]) left else right;
        if (heap.*[child] >= heap.*[root]) break;
        const heap_value = heap.*[root];
        heap.*[root] = heap.*[child];
        heap.*[child] = heap_value;
        const vertex = positions.*[root];
        positions.*[root] = positions.*[child];
        positions.*[child] = vertex;
        node_position.*[@intCast(positions.*[root])] = @intCast(root);
        node_position.*[@intCast(positions.*[child])] = @intCast(child);
        root = child;
    }
}

fn decreaseKey(
    value: i64,
    index_start: usize,
    heap: *[MAX_VERTICES]i64,
    positions: *[MAX_VERTICES]i32,
    node_position: *[MAX_VERTICES]i32,
) void {
    var index = index_start;
    const vertex = positions.*[index];
    while (index != 0) {
        const parent = (index - 1) / 2;
        if (value < heap.*[parent]) {
            heap.*[index] = heap.*[parent];
            positions.*[index] = positions.*[parent];
            node_position.*[@intCast(positions.*[parent])] = @intCast(index);
        } else {
            heap.*[index] = value;
            positions.*[index] = vertex;
            node_position.*[@intCast(vertex)] = @intCast(index);
            return;
        }
        index = parent;
    }
    heap.*[0] = value;
    positions.*[0] = vertex;
    node_position.*[@intCast(vertex)] = 0;
}

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_spanning_tree_prims(
    input_opt: ?[*]const i32,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const raw_vertices = input[0];
    const raw_edges = input[1];
    if (raw_vertices < 1 or raw_vertices > 16 or raw_edges < 0 or raw_edges > 64) return -1;
    const vertex_count: usize = @intCast(raw_vertices);
    const edge_count: usize = @intCast(raw_edges);
    if (length != 2 + 3 * edge_count) return -1;

    var neighbors = [_][MAX_VERTICES]i32{[_]i32{0} ** MAX_VERTICES} ** MAX_VERTICES;
    var weights = [_][MAX_VERTICES]i32{[_]i32{0} ** MAX_VERTICES} ** MAX_VERTICES;
    var degree = [_]usize{0} ** MAX_VERTICES;
    var seen = [_][MAX_VERTICES]bool{[_]bool{false} ** MAX_VERTICES} ** MAX_VERTICES;
    var position: usize = 2;
    for (0..edge_count) |_| {
        const u = input[position];
        const v = input[position + 1];
        const weight = input[position + 2];
        position += 3;
        if (u < 0 or v <= u or v >= raw_vertices or seen[@intCast(u)][@intCast(v)]) return -1;
        seen[@intCast(u)][@intCast(v)] = true;
        const u_index: usize = @intCast(u);
        const v_index: usize = @intCast(v);
        neighbors[u_index][degree[u_index]] = v;
        weights[u_index][degree[u_index]] = weight;
        degree[u_index] += 1;
        neighbors[v_index][degree[v_index]] = u;
        weights[v_index][degree[v_index]] = weight;
        degree[v_index] += 1;
    }

    if (vertex_count > 1) {
        var reached_vertex = [_]bool{false} ** MAX_VERTICES;
        var stack: [MAX_VERTICES]usize = undefined;
        var stack_size: usize = 1;
        var reached: usize = 0;
        stack[0] = 0;
        reached_vertex[0] = true;
        while (stack_size > 0) {
            stack_size -= 1;
            const vertex = stack[stack_size];
            reached += 1;
            for (0..degree[vertex]) |i| {
                const neighbor: usize = @intCast(neighbors[vertex][i]);
                if (!reached_vertex[neighbor]) {
                    reached_vertex[neighbor] = true;
                    stack[stack_size] = neighbor;
                    stack_size += 1;
                }
            }
        }
        if (reached != vertex_count) return -1;
    }

    var visited = [_]bool{false} ** MAX_VERTICES;
    var parent = [_]i32{0} ** MAX_VERTICES;
    var heap = [_]i64{SOURCE_HEAP_SENTINEL} ** MAX_VERTICES;
    var positions = [_]i32{0} ** MAX_VERTICES;
    var node_position = [_]i32{0} ** MAX_VERTICES;
    for (0..vertex_count) |vertex| {
        parent[vertex] = -1;
        positions[vertex] = @intCast(vertex);
        node_position[vertex] = @intCast(vertex);
    }
    visited[0] = true;
    for (0..degree[0]) |i| {
        const neighbor: usize = @intCast(neighbors[0][i]);
        parent[neighbor] = 0;
        heap[neighbor] = @as(i64, weights[0][i]);
    }
    var start = vertex_count / 2;
    while (start > 0) {
        start -= 1;
        topToBottom(&heap, &positions, &node_position, vertex_count, start);
    }

    var words = [_]i32{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 1;
    var tree_edge_count: usize = 0;
    for (1..vertex_count) |_| {
        const vertex_id = positions[0];
        const vertex: usize = @intCast(vertex_id);
        heap[0] = SOURCE_HEAP_SENTINEL;
        topToBottom(&heap, &positions, &node_position, vertex_count, 0);
        if (!visited[vertex]) {
            words[word_count] = parent[vertex];
            words[word_count + 1] = vertex_id;
            word_count += 2;
            tree_edge_count += 1;
            visited[vertex] = true;
            for (0..degree[vertex]) |i| {
                const neighbor: usize = @intCast(neighbors[vertex][i]);
                const weight: i64 = @as(i64, weights[vertex][i]);
                if (!visited[neighbor]) {
                    const heap_index: usize = @intCast(node_position[neighbor]);
                    if (weight < heap[heap_index]) {
                        heap[heap_index] = weight;
                        decreaseKey(weight, heap_index, &heap, &positions, &node_position);
                        parent[neighbor] = vertex_id;
                    }
                }
            }
        }
    }
    if (tree_edge_count != vertex_count - 1) return -1;
    words[0] = @intCast(tree_edge_count);
    const byte_count = word_count * 4;
    if (byte_count > MAX_OUTPUT_BYTES or output_opt == null or capacity < byte_count) return -2;
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    for (0..word_count) |i| putI32Le(&buffer, i * 4, words[i]);
    const output = output_opt.?;
    for (0..byte_count) |i| output[i] = buffer[i];
    return @intCast(byte_count);
}
