const MAX_POINTS: usize = 8;
const MAX_NODES: usize = 15;
const LEAF_SIZE: usize = 2;
const MAX_I64: i64 = 9223372036854775807;

const Point = struct { x: i64, y: i64 };
const Node = struct { left: i32, right: i32, start: usize, count: usize,
    min_x: i64, min_y: i64, max_x: i64, max_y: i64 };
const Tree = struct {
    points: [MAX_POINTS]Point = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS,
    order: [MAX_POINTS]usize = [_]usize{0} ** MAX_POINTS,
    scratch: [MAX_POINTS]usize = [_]usize{0} ** MAX_POINTS,
    nodes: [MAX_NODES]Node = undefined,
    used: usize = 0,
};

fn build(tree: *Tree, start: usize, count: usize) usize {
    const id = tree.used;
    tree.used += 1;
    const first = tree.points[tree.order[start]];
    var node = Node{ .left = -1, .right = -1, .start = start, .count = count,
        .min_x = first.x, .min_y = first.y, .max_x = first.x, .max_y = first.y };
    for (1..count) |i| {
        const p = tree.points[tree.order[start + i]];
        node.min_x = @min(node.min_x, p.x); node.max_x = @max(node.max_x, p.x);
        node.min_y = @min(node.min_y, p.y); node.max_y = @max(node.max_y, p.y);
    }
    if (count <= LEAF_SIZE) { tree.nodes[id] = node; return id; }
    const axis_x = (node.max_x - node.min_x) > (node.max_y - node.min_y);
    const midpoint_twice = if (axis_x) node.min_x + node.max_x else node.min_y + node.max_y;
    var left_count: usize = 0;
    for (0..count) |i| {
        const p = tree.points[tree.order[start + i]];
        const coordinate = if (axis_x) p.x else p.y;
        if (2 * coordinate < midpoint_twice) left_count += 1;
    }
    if (left_count == 0 or left_count == count) {
        left_count = (count + 1) / 2;
        for (0..count) |i| tree.scratch[i] = tree.order[start + i];
    } else {
        var l: usize = 0;
        var r = left_count;
        for (0..count) |i| {
            const index = tree.order[start + i];
            const p = tree.points[index];
            const coordinate = if (axis_x) p.x else p.y;
            if (2 * coordinate < midpoint_twice) { tree.scratch[l] = index; l += 1; }
            else { tree.scratch[r] = index; r += 1; }
        }
    }
    for (0..count) |i| tree.order[start + i] = tree.scratch[i];
    const left = build(tree, start, left_count);
    const right = build(tree, start + left_count, count - left_count);
    node.left = @intCast(left); node.right = @intCast(right); node.count = 0;
    tree.nodes[id] = node;
    return id;
}

fn boxDistance(a: Node, b: Node) i64 {
    var dx: i64 = 0; var dy: i64 = 0;
    if (a.max_x < b.min_x) dx = b.min_x - a.max_x else if (b.max_x < a.min_x) dx = a.min_x - b.max_x;
    if (a.max_y < b.min_y) dy = b.min_y - a.max_y else if (b.max_y < a.min_y) dy = a.min_y - b.max_y;
    return dx * dx + dy * dy;
}
fn search(a: *const Tree, ai: usize, b: *const Tree, bi: usize, best: *i64) void {
    const na = a.nodes[ai]; const nb = b.nodes[bi];
    if (boxDistance(na, nb) > best.*) return;
    const a_leaf = na.left < 0; const b_leaf = nb.left < 0;
    if (a_leaf and b_leaf) {
        for (0..na.count) |i| {
            const p = a.points[a.order[na.start + i]];
            for (0..nb.count) |j| {
                const q = b.points[b.order[nb.start + j]];
                const dx = p.x - q.x; const dy = p.y - q.y; const d = dx * dx + dy * dy;
                if (d < best.*) best.* = d;
            }
        }
    } else if (a_leaf) {
        const l: usize = @intCast(nb.left); const r: usize = @intCast(nb.right);
        if (boxDistance(na, b.nodes[l]) < boxDistance(na, b.nodes[r])) { search(a, ai, b, l, best); search(a, ai, b, r, best); }
        else { search(a, ai, b, r, best); search(a, ai, b, l, best); }
    } else if (b_leaf) {
        const l: usize = @intCast(na.left); const r: usize = @intCast(na.right);
        if (boxDistance(nb, a.nodes[l]) < boxDistance(nb, a.nodes[r])) { search(a, l, b, bi, best); search(a, r, b, bi, best); }
        else { search(a, r, b, bi, best); search(a, l, b, bi, best); }
    } else {
        var pairs = [_][2]usize{ .{ @intCast(na.left), @intCast(nb.left) }, .{ @intCast(na.left), @intCast(nb.right) },
            .{ @intCast(na.right), @intCast(nb.left) }, .{ @intCast(na.right), @intCast(nb.right) } };
        var distances: [4]i64 = undefined;
        for (0..4) |i| distances[i] = boxDistance(a.nodes[pairs[i][0]], b.nodes[pairs[i][1]]);
        for (1..4) |i| {
            const pair = pairs[i]; const d = distances[i]; var j = i;
            while (j > 0 and d < distances[j - 1]) : (j -= 1) { pairs[j] = pairs[j - 1]; distances[j] = distances[j - 1]; }
            pairs[j] = pair; distances[j] = d;
        }
        for (pairs) |pair| search(a, pair[0], b, pair[1], best);
    }
}
fn writeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[i] = @truncate(bits >> @intCast(8 * i));
}

// Clean-room bounded ParGeo profile; see package LICENSE.txt for the complete MIT notice.
export fn pargeo_bichromatic_closest_pair(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 10 or length > 34) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > 8 or values[1] < 2 or values[1] > 8) return -1;
    const na: usize = @intCast(values[0]); const nb: usize = @intCast(values[1]);
    if (length != 2 + 2 * (na + nb)) return -1;
    for (2..length) |i| if (values[i] < -1_000_000 or values[i] > 1_000_000) return -1;
    if (output == null or capacity < 8) return -2;
    var a = Tree{}; var b = Tree{};
    for (0..na) |i| { a.points[i] = .{ .x = values[2 + 2 * i], .y = values[3 + 2 * i] }; a.order[i] = i; }
    const offset = 2 + 2 * na;
    for (0..nb) |i| { b.points[i] = .{ .x = values[offset + 2 * i], .y = values[offset + 2 * i + 1] }; b.order[i] = i; }
    const root_a = build(&a, 0, na); const root_b = build(&b, 0, nb);
    var best = MAX_I64;
    search(&a, root_a, &b, root_b, &best);
    writeI64Le(output.?, best);
    return 8;
}
