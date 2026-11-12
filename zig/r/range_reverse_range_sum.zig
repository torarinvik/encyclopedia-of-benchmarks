const MAX_N: usize = 64;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 163;
const NONE: usize = MAX_N;

const Node = struct { left: usize = NONE, right: usize = NONE, size: usize = 1, value: i64 = 0, total: i64 = 0, priority: u64 = 0, reversed: bool = false };
const Operation = struct { kind: i64, left: usize, right: usize };
const Parts = struct { first: usize, second: usize };

fn priority_for(index: usize) u64 {
    var state: i64 = 1;
    for (0..index + 1) |_| state = @mod(state * 48271, 2147483647);
    return @intCast(state);
}
fn node_size(nodes: *const [MAX_N]Node, index: usize) usize { return if (index == NONE) 0 else nodes[index].size; }
fn node_sum(nodes: *const [MAX_N]Node, index: usize) i64 { return if (index == NONE) 0 else nodes[index].total; }
fn higher(nodes: *const [MAX_N]Node, a: usize, b: usize) bool {
    if (nodes[a].priority != nodes[b].priority) return nodes[a].priority > nodes[b].priority;
    return a > b;
}
fn pull(nodes: *[MAX_N]Node, index: usize) void {
    nodes[index].size = 1 + node_size(nodes, nodes[index].left) + node_size(nodes, nodes[index].right);
    nodes[index].total = nodes[index].value + node_sum(nodes, nodes[index].left) + node_sum(nodes, nodes[index].right);
}
fn reverse_node(nodes: *[MAX_N]Node, index: usize) void {
    if (index == NONE) return;
    const temp = nodes[index].left; nodes[index].left = nodes[index].right; nodes[index].right = temp;
    nodes[index].reversed = !nodes[index].reversed;
}
fn push(nodes: *[MAX_N]Node, index: usize) void {
    if (!nodes[index].reversed) return;
    reverse_node(nodes, nodes[index].left); reverse_node(nodes, nodes[index].right); nodes[index].reversed = false;
}
fn split(nodes: *[MAX_N]Node, root: usize, count: usize) Parts {
    if (root == NONE) return .{ .first = NONE, .second = NONE };
    push(nodes, root);
    if (node_size(nodes, nodes[root].left) >= count) {
        const p = split(nodes, nodes[root].left, count); nodes[root].left = p.second; pull(nodes, root);
        return .{ .first = p.first, .second = root };
    }
    const p = split(nodes, nodes[root].right, count - node_size(nodes, nodes[root].left) - 1);
    nodes[root].right = p.first; pull(nodes, root);
    return .{ .first = root, .second = p.second };
}
fn merge(nodes: *[MAX_N]Node, left: usize, right: usize) usize {
    if (left == NONE) return right;
    if (right == NONE) return left;
    if (higher(nodes, left, right)) {
        push(nodes, left); nodes[left].right = merge(nodes, nodes[left].right, right); pull(nodes, left); return left;
    }
    push(nodes, right); nodes[right].left = merge(nodes, left, nodes[right].left); pull(nodes, right); return right;
}
fn put64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |j| output[offset + j] = @truncate(bits >> @intCast(8 * j));
}

pub export fn range_reverse_range_sum(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?; const nv = input[0]; const qv = input[1];
    if (nv < 0 or nv > MAX_N or qv < 0 or qv > MAX_Q) return -1;
    const n: usize = @intCast(nv); const q: usize = @intCast(qv);
    if (length < 2 + n) return -1;
    var nodes = [_]Node{.{}} ** MAX_N;
    var offset: usize = 2;
    for (0..n) |i| {
        const value = input[offset]; offset += 1;
        if (value < 0 or value > 1_000_000_000) return -1;
        nodes[i] = .{ .left = NONE, .right = NONE, .size = 1, .value = value, .total = value, .priority = priority_for(i) };
    }
    var operations = [_]Operation{.{ .kind = 0, .left = 0, .right = 0 }} ** MAX_Q;
    var query_count: usize = 0;
    for (0..q) |i| {
        if (offset + 3 > length) return -1;
        const kind = input[offset]; const left = input[offset + 1]; const right = input[offset + 2]; offset += 3;
        if ((kind != 0 and kind != 1) or left < 0 or left > right or right > nv) return -1;
        operations[i] = .{ .kind = kind, .left = @intCast(left), .right = @intCast(right) };
        if (kind == 1) query_count += 1;
    }
    if (offset != length) return -1;
    var root: usize = NONE;
    for (0..n) |i| root = merge(&nodes, root, i);
    var answers = [_]i64{0} ** MAX_Q; var answer_count: usize = 0;
    for (0..q) |i| {
        const op = operations[i]; const p = split(&nodes, root, op.right); const m = split(&nodes, p.first, op.left);
        if (op.kind == 0) reverse_node(&nodes, m.second) else { answers[answer_count] = node_sum(&nodes, m.second); answer_count += 1; }
        root = merge(&nodes, merge(&nodes, m.first, m.second), p.second);
    }
    const bytes = 8 * query_count;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..query_count) |i| put64(output, 8 * i, answers[i]);
    return @intCast(bytes);
}
