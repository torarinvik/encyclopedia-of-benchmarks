const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = MAX_VERTICES * (MAX_VERTICES - 1) / 2;
const MAX_VALID_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;
const WEIGHT_MIN: i64 = -1_000_000;
const WEIGHT_MAX: i64 = 1_000_000;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

const Edge = struct { left: usize, right: usize, weight: i32 };

fn siftDown(edges: *[MAX_EDGES]Edge, root_arg: usize, end: usize) void {
    var root = root_arg;
    while (root * 2 + 1 < end) {
        var child = root * 2 + 1;
        if (child + 1 < end and edges[child].weight < edges[child + 1].weight) child += 1;
        if (edges[root].weight >= edges[child].weight) return;
        const temporary = edges[root];
        edges[root] = edges[child];
        edges[child] = temporary;
        root = child;
    }
}

fn sortEdges(edges: *[MAX_EDGES]Edge, count: usize) void {
    var start = count / 2;
    while (start > 0) {
        start -= 1;
        siftDown(edges, start, count);
    }
    var end = count;
    while (end > 1) {
        end -= 1;
        const temporary = edges[0];
        edges[0] = edges[end];
        edges[end] = temporary;
        siftDown(edges, 0, end);
    }
}

fn findRoot(parent: *[MAX_VERTICES]usize, vertex: usize) usize {
    var root = vertex;
    while (parent[root] != root) root = parent[root];
    var current = vertex;
    while (parent[current] != current) {
        const next = parent[current];
        parent[current] = root;
        current = next;
    }
    return root;
}

fn unionSets(parent: *[MAX_VERTICES]usize, ranks: *[MAX_VERTICES]usize, left: usize, right: usize) bool {
    const left_root = findRoot(parent, left);
    const right_root = findRoot(parent, right);
    if (left_root == right_root) return false;
    if (ranks[left_root] < ranks[right_root]) {
        parent[left_root] = right_root;
    } else {
        parent[right_root] = left_root;
        if (ranks[left_root] == ranks[right_root]) ranks[left_root] += 1;
    }
    return true;
}

fn hashByte(hash_arg: u64, byte: u8) u64 {
    return (hash_arg ^ @as(u64, byte)) *% FNV_PRIME;
}

fn hashU16(hash_arg: u64, value: u16) u64 {
    var hash = hash_arg;
    for (0..2) |byte| hash = hashByte(hash, @truncate(value >> @intCast(8 * byte)));
    return hash;
}

fn hashI32(hash_arg: u64, value: i32) u64 {
    var hash = hash_arg;
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| hash = hashByte(hash, @truncate(bits >> @intCast(8 * byte)));
    return hash;
}

fn hashI64(hash_arg: u64, value: i64) u64 {
    var hash = hash_arg;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| hash = hashByte(hash, @truncate(bits >> @intCast(8 * byte)));
    return hash;
}

export fn kruskal_mst(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, MAX_VERTICES) or input[1] < 0 or input[1] > @as(i64, MAX_EDGES)) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 3 * edge_count or length > MAX_VALID_INPUT_LENGTH) return -1;
    const maximum_for_graph = vertex_count * (vertex_count - 1) / 2;
    if (edge_count > maximum_for_graph or (vertex_count == 1 and edge_count != 0) or
        (vertex_count > 1 and edge_count < vertex_count - 1)) return -1;

    var edges: [MAX_EDGES]Edge = undefined;
    var seen_pairs: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    for (0..edge_count) |index| {
        const offset = 2 + 3 * index;
        const raw_left = input[offset];
        const raw_right = input[offset + 1];
        const raw_weight = input[offset + 2];
        if (raw_left < 0 or raw_left >= @as(i64, @intCast(vertex_count)) or
            raw_right < 0 or raw_right >= @as(i64, @intCast(vertex_count)) or
            raw_left == raw_right or raw_weight < WEIGHT_MIN or raw_weight > WEIGHT_MAX) return -1;
        const first: usize = @intCast(raw_left);
        const second: usize = @intCast(raw_right);
        const lower = @min(first, second);
        const upper = @max(first, second);
        const pair_index = lower * MAX_VERTICES + upper;
        if (seen_pairs[pair_index]) return -1;
        seen_pairs[pair_index] = true;
        edges[index] = .{ .left = lower, .right = upper, .weight = @intCast(raw_weight) };
    }
    sortEdges(&edges, edge_count);
    if (edge_count > 1) {
        for (1..edge_count) |index| {
            if (edges[index - 1].weight == edges[index].weight) return -1;
        }
    }

    var parent: [MAX_VERTICES]usize = @splat(0);
    var ranks: [MAX_VERTICES]usize = @splat(0);
    for (0..vertex_count) |vertex| parent[vertex] = vertex;
    var accepted: [MAX_VERTICES - 1]Edge = undefined;
    var accepted_count: usize = 0;
    var total_weight: i64 = 0;
    for (0..edge_count) |index| {
        if (accepted_count == vertex_count - 1) break;
        if (unionSets(&parent, &ranks, edges[index].left, edges[index].right)) {
            accepted[accepted_count] = edges[index];
            accepted_count += 1;
            total_weight += @as(i64, edges[index].weight);
        }
    }
    if (accepted_count != vertex_count - 1) return -1;

    var hash: u64 = FNV_OFFSET;
    hash = hashU16(hash, @intCast(vertex_count));
    hash = hashU16(hash, @intCast(accepted_count));
    for (0..accepted_count) |index| {
        hash = hashU16(hash, @intCast(accepted[index].left));
        hash = hashU16(hash, @intCast(accepted[index].right));
        hash = hashI32(hash, accepted[index].weight);
    }
    hash = hashI64(hash, total_weight);
    return @intCast(hash & 0x7fffffffffffffff);
}
