const MOD: i64 = 998244353;
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_NODES: usize = 64;
const MAX_INPUT: usize = 195;
const NONE: usize = MAX_NODES;

const Node = struct { left: usize = NONE, right: usize = NONE, size: usize = 1, value: i64 = 0, total: i64 = 0, mul: i64 = 1, add: i64 = 0, priority: u64 = 0, reversed: bool = false };
const Operation = struct { kind: usize = 0, left: usize = 0, right: usize = 0, node: usize = NONE, mul: i64 = 0, add: i64 = 0 };
const Parts = struct { first: usize, second: usize };

fn priority_for(id: usize) u64 { var state: i64 = 1; for (0..id + 1) |_| state = @mod(state * 48271, 2147483647); return @intCast(state); }
fn node_size(nodes: *const [MAX_NODES]Node, index: usize) usize { return if (index == NONE) 0 else nodes[index].size; }
fn node_sum(nodes: *const [MAX_NODES]Node, index: usize) i64 { return if (index == NONE) 0 else nodes[index].total; }
fn higher(nodes: *const [MAX_NODES]Node, a: usize, b: usize) bool { if (nodes[a].priority != nodes[b].priority) return nodes[a].priority > nodes[b].priority; return a > b; }
fn pull(nodes: *[MAX_NODES]Node, index: usize) void { nodes[index].size = 1 + node_size(nodes, nodes[index].left) + node_size(nodes, nodes[index].right); nodes[index].total = @mod(nodes[index].value + node_sum(nodes, nodes[index].left) + node_sum(nodes, nodes[index].right), MOD); }
fn affine(nodes: *[MAX_NODES]Node, index: usize, m: i64, a: i64) void { if (index == NONE) return; nodes[index].value = @mod(m * nodes[index].value + a, MOD); nodes[index].total = @mod(m * nodes[index].total + a * @as(i64, @intCast(nodes[index].size)), MOD); nodes[index].mul = @mod(m * nodes[index].mul, MOD); nodes[index].add = @mod(m * nodes[index].add + a, MOD); }
fn reverse_node(nodes: *[MAX_NODES]Node, index: usize) void { if (index == NONE) return; const child = nodes[index].left; nodes[index].left = nodes[index].right; nodes[index].right = child; nodes[index].reversed = !nodes[index].reversed; }
fn push(nodes: *[MAX_NODES]Node, index: usize) void { if (nodes[index].mul != 1 or nodes[index].add != 0) { affine(nodes, nodes[index].left, nodes[index].mul, nodes[index].add); affine(nodes, nodes[index].right, nodes[index].mul, nodes[index].add); nodes[index].mul = 1; nodes[index].add = 0; } if (nodes[index].reversed) { reverse_node(nodes, nodes[index].left); reverse_node(nodes, nodes[index].right); nodes[index].reversed = false; } }
fn split(nodes: *[MAX_NODES]Node, root: usize, count: usize) Parts { if (root == NONE) return .{ .first = NONE, .second = NONE }; push(nodes, root); if (node_size(nodes, nodes[root].left) >= count) { const p = split(nodes, nodes[root].left, count); nodes[root].left = p.second; pull(nodes, root); return .{ .first = p.first, .second = root }; } const p = split(nodes, nodes[root].right, count - node_size(nodes, nodes[root].left) - 1); nodes[root].right = p.first; pull(nodes, root); return .{ .first = root, .second = p.second }; }
fn merge(nodes: *[MAX_NODES]Node, left: usize, right: usize) usize { if (left == NONE) return right; if (right == NONE) return left; if (higher(nodes, left, right)) { push(nodes, left); nodes[left].right = merge(nodes, nodes[left].right, right); pull(nodes, left); return left; } push(nodes, right); nodes[right].left = merge(nodes, left, nodes[right].left); pull(nodes, right); return right; }
fn put64(output: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |j| output[offset + j] = @truncate(bits >> @intCast(8 * j)); }

pub export fn dynamic_sequence_range_affine_range_sum(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?; const n_value = input[0]; const q_value = input[1];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_N)) or q_value < 0 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value); const q: usize = @intCast(q_value); if (length < 2 + n) return -1;
    var nodes = [_]Node{.{}} ** MAX_NODES; var offset: usize = 2;
    for (0..n) |i| { const value = input[offset]; offset += 1; if (value < 0 or value >= MOD) return -1; nodes[i] = .{ .left = NONE, .right = NONE, .size = 1, .value = value, .total = value, .mul = 1, .add = 0, .priority = priority_for(i) }; }
    var operations = [_]Operation{.{}} ** MAX_Q; var current = n; var node_count = n; var queries: usize = 0;
    for (0..q) |i| {
        if (offset >= length) return -1; const tag = input[offset]; offset += 1; if (tag < 0 or tag > 4) return -1;
        var op = Operation{ .kind = @intCast(tag) };
        if (tag == 0) {
            if (offset + 2 > length) return -1; const at = input[offset]; const value = input[offset + 1]; offset += 2;
            if (at < 0 or @as(u64, @intCast(at)) > @as(u64, @intCast(current)) or current >= MAX_NODES or value < 0 or value >= MOD) return -1;
            op.left = @intCast(at); op.node = node_count; nodes[node_count] = .{ .left = NONE, .right = NONE, .size = 1, .value = value, .total = value, .mul = 1, .add = 0, .priority = priority_for(node_count) }; node_count += 1; current += 1;
        } else if (tag == 1) {
            if (offset >= length) return -1; const at = input[offset]; offset += 1; if (at < 0 or @as(u64, @intCast(at)) >= @as(u64, @intCast(current))) return -1; op.left = @intCast(at); current -= 1;
        } else if (tag == 2 or tag == 4) {
            if (offset + 2 > length) return -1; const left = input[offset]; const right = input[offset + 1]; offset += 2;
            if (left < 0 or left > right or right < 0 or @as(u64, @intCast(right)) > @as(u64, @intCast(current))) return -1; op.left = @intCast(left); op.right = @intCast(right); if (tag == 4) queries += 1;
        } else {
            if (offset + 4 > length) return -1; const left = input[offset]; const right = input[offset + 1]; const mul = input[offset + 2]; const add = input[offset + 3]; offset += 4;
            if (left < 0 or left > right or right < 0 or @as(u64, @intCast(right)) > @as(u64, @intCast(current)) or mul < 0 or mul >= MOD or add < 0 or add >= MOD) return -1; op.left = @intCast(left); op.right = @intCast(right); op.mul = mul; op.add = add;
        }
        operations[i] = op;
    }
    if (offset != length) return -1; var root: usize = NONE; for (0..n) |i| root = merge(&nodes, root, i);
    var answers = [_]i64{0} ** MAX_Q; var answer_count: usize = 0;
    for (0..q) |i| {
        const op = operations[i]; const p = split(&nodes, root, op.left);
        if (op.kind == 0) { root = merge(&nodes, merge(&nodes, p.first, op.node), p.second); continue; }
        var middle: usize = NONE; var tail: usize = NONE;
        if (op.kind == 1) { const m = split(&nodes, p.second, 1); middle = m.first; tail = m.second; root = merge(&nodes, p.first, tail); continue; }
        else { const m = split(&nodes, p.second, op.right - op.left); middle = m.first; tail = m.second; if (op.kind == 2) reverse_node(&nodes, middle) else if (op.kind == 3) affine(&nodes, middle, op.mul, op.add) else { answers[answer_count] = node_sum(&nodes, middle); answer_count += 1; } }
        root = merge(&nodes, merge(&nodes, p.first, middle), tail);
    }
    const bytes = 8 * queries; if (output_opt == null or capacity < bytes) return -2; const output = output_opt.?; for (0..queries) |i| put64(output, 8 * i, answers[i]); return @intCast(bytes);
}
