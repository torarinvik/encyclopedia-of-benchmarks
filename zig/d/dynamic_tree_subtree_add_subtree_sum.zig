const MAX_N: usize = 16;
const MAX_Q: usize = 32;
const MAX_TOKENS: usize = MAX_N + 2 * (MAX_N - 1 + MAX_Q);
const MAX_INPUT: usize = 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_DELTA: i64 = 1000;

const Node = struct {
    left: i32 = -1,
    right: i32 = -1,
    parent: i32 = -1,
    priority: u32 = 0,
    sequence_size: usize = 0,
    marker_count: usize = 0,
    marker: bool = false,
    own_value: i64 = 0,
    sum: i64 = 0,
    lazy_add: i64 = 0,
};
const Split = struct { first: i32, second: i32 };
const EdgeTokens = struct { forward: i32, reverse: i32 };
const Tour = struct {
    nodes: [MAX_TOKENS]Node = [_]Node{.{}} ** MAX_TOKENS,
    next_node: usize = 0,
    random_state: u32 = 0x9e3779b9,
};

fn seqSize(tour: *const Tour, id: i32) usize {
    if (id < 0) return 0;
    return tour.nodes[@intCast(id)].sequence_size;
}
fn markerCount(tour: *const Tour, id: i32) usize {
    if (id < 0) return 0;
    return tour.nodes[@intCast(id)].marker_count;
}
fn nodeSum(tour: *const Tour, id: i32) i64 {
    if (id < 0) return 0;
    return tour.nodes[@intCast(id)].sum;
}
fn pull(tour: *Tour, id: i32) void {
    const i: usize = @intCast(id);
    const node = tour.nodes[i];
    tour.nodes[i].sequence_size = 1 + seqSize(tour, node.left) + seqSize(tour, node.right);
    tour.nodes[i].marker_count = @as(usize, @intFromBool(node.marker)) + markerCount(tour, node.left) + markerCount(tour, node.right);
    tour.nodes[i].sum = node.own_value + nodeSum(tour, node.left) + nodeSum(tour, node.right);
}
fn applyAdd(tour: *Tour, id: i32, delta: i64) void {
    if (id < 0) return;
    const i: usize = @intCast(id);
    if (tour.nodes[i].marker_count == 0) return;
    tour.nodes[i].sum += delta * @as(i64, @intCast(tour.nodes[i].marker_count));
    if (tour.nodes[i].marker) tour.nodes[i].own_value += delta;
    tour.nodes[i].lazy_add += delta;
}
fn push(tour: *Tour, id: i32) void {
    const i: usize = @intCast(id);
    const delta = tour.nodes[i].lazy_add;
    if (delta == 0) return;
    const left = tour.nodes[i].left;
    const right = tour.nodes[i].right;
    applyAdd(tour, left, delta);
    applyAdd(tour, right, delta);
    tour.nodes[i].lazy_add = 0;
}
fn nextPriority(tour: *Tour) u32 {
    var x = tour.random_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    tour.random_state = x;
    return x;
}
fn newNode(tour: *Tour, marker: bool, value: i64) i32 {
    if (tour.next_node >= MAX_TOKENS) return -1;
    const id = tour.next_node;
    tour.next_node += 1;
    tour.nodes[id] = .{
        .left = -1, .right = -1, .parent = -1, .priority = nextPriority(tour),
        .sequence_size = 1, .marker_count = @as(usize, @intFromBool(marker)), .marker = marker,
        .own_value = if (marker) value else 0, .sum = if (marker) value else 0,
    };
    return @intCast(id);
}
fn split(tour: *Tour, root: i32, count: usize) Split {
    if (root < 0) return .{ .first = -1, .second = -1 };
    push(tour, root);
    const i: usize = @intCast(root);
    tour.nodes[i].parent = -1;
    const left = tour.nodes[i].left;
    if (seqSize(tour, left) >= count) {
        const parts = split(tour, left, count);
        tour.nodes[i].left = parts.second;
        if (parts.second >= 0) tour.nodes[@intCast(parts.second)].parent = root;
        pull(tour, root);
        tour.nodes[i].parent = -1;
        return .{ .first = parts.first, .second = root };
    }
    const right = tour.nodes[i].right;
    const parts = split(tour, right, count - seqSize(tour, left) - 1);
    tour.nodes[i].right = parts.first;
    if (parts.first >= 0) tour.nodes[@intCast(parts.first)].parent = root;
    pull(tour, root);
    tour.nodes[i].parent = -1;
    return .{ .first = root, .second = parts.second };
}
fn merge(tour: *Tour, first: i32, second: i32) i32 {
    if (first < 0) {
        if (second >= 0) tour.nodes[@intCast(second)].parent = -1;
        return second;
    }
    if (second < 0) { tour.nodes[@intCast(first)].parent = -1; return first; }
    tour.nodes[@intCast(first)].parent = -1;
    tour.nodes[@intCast(second)].parent = -1;
    if (tour.nodes[@intCast(first)].priority >= tour.nodes[@intCast(second)].priority) {
        push(tour, first);
        const child = tour.nodes[@intCast(first)].right;
        const joined = merge(tour, child, second);
        tour.nodes[@intCast(first)].right = joined;
        if (joined >= 0) tour.nodes[@intCast(joined)].parent = first;
        pull(tour, first);
        return first;
    }
    push(tour, second);
    const child = tour.nodes[@intCast(second)].left;
    const joined = merge(tour, first, child);
    tour.nodes[@intCast(second)].left = joined;
    if (joined >= 0) tour.nodes[@intCast(joined)].parent = second;
    pull(tour, second);
    return second;
}
fn rootOf(tour: *const Tour, start: i32) i32 {
    var id = start;
    while (tour.nodes[@intCast(id)].parent >= 0) id = tour.nodes[@intCast(id)].parent;
    return id;
}
fn rankOf(tour: *const Tour, start: i32) usize {
    var id = start;
    var rank = seqSize(tour, tour.nodes[@intCast(id)].left);
    while (tour.nodes[@intCast(id)].parent >= 0) {
        const parent = tour.nodes[@intCast(id)].parent;
        if (tour.nodes[@intCast(parent)].right == id)
            rank += 1 + seqSize(tour, tour.nodes[@intCast(parent)].left);
        id = parent;
    }
    return rank;
}
fn rotateTo(tour: *Tour, id: i32) i32 {
    const parts = split(tour, rootOf(tour, id), rankOf(tour, id));
    return merge(tour, parts.second, parts.first);
}
fn linkTours(tour: *Tour, markers: *const [MAX_N]i32, u: usize, v: usize) ?EdgeTokens {
    const root_u = rootOf(tour, markers[u]);
    const root_v = rootOf(tour, markers[v]);
    if (root_u == root_v) return null;
    const parts_a = split(tour, root_u, rankOf(tour, markers[u]) + 1);
    const parts_b = split(tour, root_v, rankOf(tour, markers[v]));
    const parts_b2 = split(tour, parts_b.second, 1);
    const uv = newNode(tour, false, 0);
    const vu = newNode(tour, false, 0);
    if (uv < 0 or vu < 0) return null;
    var root = merge(tour, parts_a.first, uv);
    root = merge(tour, root, parts_b2.second);
    root = merge(tour, root, parts_b.first);
    root = merge(tour, root, parts_b2.first);
    root = merge(tour, root, vu);
    _ = merge(tour, root, parts_a.second);
    return .{ .forward = uv, .reverse = vu };
}
fn cutTours(tour: *Tour, uv: i32, vu: i32) bool {
    const root = rotateTo(tour, uv);
    const reverse_rank = rankOf(tour, vu);
    if (reverse_rank == 0) return false;
    const first_parts = split(tour, root, 1);
    const middle_parts = split(tour, first_parts.second, reverse_rank - 1);
    const last_parts = split(tour, middle_parts.second, 1);
    if (first_parts.first != uv or last_parts.first != vu) return false;
    tour.nodes[@intCast(uv)].left = -1; tour.nodes[@intCast(uv)].right = -1; tour.nodes[@intCast(uv)].parent = -1;
    tour.nodes[@intCast(vu)].left = -1; tour.nodes[@intCast(vu)].right = -1; tour.nodes[@intCast(vu)].parent = -1;
    return true;
}
fn sideOperation(tour: *Tour, uv: i32, vu: i32, delta: ?i64) ?i64 {
    const root = rotateTo(tour, uv);
    const reverse_rank = rankOf(tour, vu);
    if (reverse_rank == 0) return null;
    const edge_parts = split(tour, root, 1);
    const side_parts = split(tour, edge_parts.second, reverse_rank - 1);
    if (edge_parts.first != uv or side_parts.first < 0) return null;
    var answer: i64 = 0;
    if (delta) |amount| {
        applyAdd(tour, side_parts.first, amount);
    } else {
        answer = nodeSum(tour, side_parts.first);
    }
    const joined = merge(tour, edge_parts.first, side_parts.first);
    _ = merge(tour, joined, side_parts.second);
    return answer;
}
fn connected(adjacency: *const [MAX_N][MAX_N]bool, n: usize, start: usize, goal: usize) bool {
    var seen = [_]bool{false} ** MAX_N;
    var queue = [_]usize{0} ** MAX_N;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = start; seen[start] = true;
    while (head < tail) : (head += 1) {
        const u = queue[head];
        if (u == goal) return true;
        for (0..n) |v| if (adjacency[u][v] and !seen[v]) {
            seen[v] = true; queue[tail] = v; tail += 1;
        };
    }
    return false;
}
fn validateFields(input: [*c]const i64, n: usize, q: usize, queries: *usize) bool {
    for (0..n) |i| if (input[2 + i] < 0 or input[2 + i] > MAX_DELTA) return false;
    const edge_start = 2 + n;
    for (0..(n - 1)) |i| {
        const u = input[edge_start + 2 * i]; const v = input[edge_start + 2 * i + 1];
        if (u < 0 or u >= n or v < 0 or v >= n or u == v) return false;
    }
    const operations = edge_start + 2 * (n - 1);
    queries.* = 0;
    for (0..q) |i| {
        const at = operations + 5 * i;
        const kind = input[at]; const v = input[at + 1]; const p = input[at + 2];
        const a = input[at + 3]; const b = input[at + 4];
        if (kind == 0) {
            if (v < 0 or v >= n or p < 0 or p >= n or a < 0 or a >= n or b < 0 or b >= n or v == p or a == b) return false;
        } else if (kind == 1) {
            if (v < 0 or v >= n or p < 0 or p >= n or v == p or a < 0 or a > MAX_DELTA or b != 0) return false;
        } else if (kind == 2) {
            if (v < 0 or v >= n or p < 0 or p >= n or v == p or a != 0 or b != 0) return false;
            queries.* += 1;
        } else return false;
    }
    return true;
}
fn validateTopology(input: [*c]const i64, n: usize, q: usize) bool {
    var adjacency = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    const edge_start = 2 + n;
    const operations = edge_start + 2 * (n - 1);
    for (0..(n - 1)) |i| {
        const u: usize = @intCast(input[edge_start + 2 * i]); const v: usize = @intCast(input[edge_start + 2 * i + 1]);
        if (adjacency[u][v]) return false;
        adjacency[u][v] = true; adjacency[v][u] = true;
    }
    for (0..n) |v| if (!connected(&adjacency, n, 0, v)) return false;
    for (0..q) |i| {
        const at = operations + 5 * i;
        const kind: usize = @intCast(input[at]); const v: usize = @intCast(input[at + 1]); const p: usize = @intCast(input[at + 2]);
        if (kind == 0) {
            const a: usize = @intCast(input[at + 3]); const b: usize = @intCast(input[at + 4]);
            if (!adjacency[v][p]) return false;
            adjacency[v][p] = false; adjacency[p][v] = false;
            if (connected(&adjacency, n, a, b)) return false;
            adjacency[a][b] = true; adjacency[b][a] = true;
        } else if (!adjacency[v][p]) return false;
    }
    return true;
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dynamic_tree_subtree_add_subtree_sum(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT) return -1;
    const n64 = input[0]; const q64 = input[1];
    if (n64 < 1 or n64 > MAX_N or q64 < 0 or q64 > MAX_Q) return -1;
    const n: usize = @intCast(n64); const q: usize = @intCast(q64);
    if (input_length != 3 * n + 5 * q) return -1;
    var queries: usize = 0;
    if (!validateFields(input, n, q, &queries) or !validateTopology(input, n, q)) return -1;
    const output_bytes = 8 * queries;
    if (output_bytes > 0 and (output == null or output_capacity < output_bytes)) return -2;

    var tour = Tour{};
    var markers = [_]i32{-1} ** MAX_N;
    for (0..n) |i| markers[i] = newNode(&tour, true, input[2 + i]);
    var directed = [_][MAX_N]i32{[_]i32{-1} ** MAX_N} ** MAX_N;
    const edge_start = 2 + n; const operations = edge_start + 2 * (n - 1);
    for (0..(n - 1)) |i| {
        const u: usize = @intCast(input[edge_start + 2 * i]); const v: usize = @intCast(input[edge_start + 2 * i + 1]);
        const edge = linkTours(&tour, &markers, u, v) orelse return -1;
        directed[u][v] = edge.forward; directed[v][u] = edge.reverse;
    }
    var answers = [_]i64{0} ** MAX_Q;
    var answer_count: usize = 0;
    for (0..q) |i| {
        const at = operations + 5 * i;
        const kind: usize = @intCast(input[at]); const v: usize = @intCast(input[at + 1]); const p: usize = @intCast(input[at + 2]);
        if (kind == 0) {
            const a: usize = @intCast(input[at + 3]); const b: usize = @intCast(input[at + 4]);
            const uv = directed[v][p]; const vu = directed[p][v];
            if (uv < 0 or vu < 0 or !cutTours(&tour, uv, vu)) return -1;
            directed[v][p] = -1; directed[p][v] = -1;
            const edge = linkTours(&tour, &markers, a, b) orelse return -1;
            directed[a][b] = edge.forward; directed[b][a] = edge.reverse;
        } else if (kind == 1) {
            if (sideOperation(&tour, directed[p][v], directed[v][p], input[at + 3]) == null) return -1;
        } else {
            const answer = sideOperation(&tour, directed[p][v], directed[v][p], null) orelse return -1;
            answers[answer_count] = answer; answer_count += 1;
        }
    }
    for (0..answer_count) |i| putI64(output, 8 * i, answers[i]);
    return @intCast(output_bytes);
}
