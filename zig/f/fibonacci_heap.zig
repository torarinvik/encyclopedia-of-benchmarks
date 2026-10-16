const Node = struct { key: i64 = 0, degree: usize = 0, child: i32 = -1, parent: i32 = -1, left: i32 = -1, right: i32 = -1 };
fn remove(nodes: *[128]Node, x: i32) void { const i: usize = @intCast(x); nodes[@intCast(nodes[i].left)].right = nodes[i].right; nodes[@intCast(nodes[i].right)].left = nodes[i].left; }
fn addRoot(nodes: *[128]Node, minimum: *i32, x: i32) void {
    const i: usize = @intCast(x);
    nodes[i].parent = -1;
    if (minimum.* == -1) { nodes[i].left = x; nodes[i].right = x; minimum.* = x; return; }
    const m: usize = @intCast(minimum.*); const r = nodes[m].right;
    nodes[i].left = minimum.*; nodes[i].right = r; nodes[m].right = x; nodes[@intCast(r)].left = x;
    if (nodes[i].key < nodes[m].key) minimum.* = x;
}
fn linkChild(nodes: *[128]Node, parent: i32, child: i32) void {
    remove(nodes, child); const p: usize = @intCast(parent); const c: usize = @intCast(child); nodes[c].parent = parent;
    if (nodes[p].child == -1) { nodes[c].left = child; nodes[c].right = child; nodes[p].child = child; }
    else { const first = nodes[p].child; const right = nodes[@intCast(first)].right; nodes[c].left = first; nodes[c].right = right; nodes[@intCast(first)].right = child; nodes[@intCast(right)].left = child; }
    nodes[p].degree += 1;
}
fn consolidate(nodes: *[128]Node, minimum: *i32) void {
    var roots: [128]i32 = undefined; var count: usize = 0; var x = minimum.*;
    if (x == -1) return;
    while (true) { roots[count] = x; count += 1; x = nodes[@intCast(x)].right; if (x == minimum.*) break; }
    var table: [129]i32 = undefined; @memset(&table, -1);
    for (roots[0..count]) |root| { if (nodes[@intCast(root)].parent != -1) continue; x = root; var d = nodes[@intCast(x)].degree; while (table[d] != -1) { var y = table[d]; if (nodes[@intCast(y)].key < nodes[@intCast(x)].key) { const t = x; x = y; y = t; } table[d] = -1; linkChild(nodes, x, y); d = nodes[@intCast(x)].degree; } table[d] = x; }
    minimum.* = -1;
    for (table) |root| if (root != -1) addRoot(nodes, minimum, root);
}
fn storeLe(output: [*]u8, offset: usize, value: i64) void { var bits: u64 = @bitCast(value); for (0..8) |b| { output[offset+b] = @truncate(bits); bits >>= 8; } }
pub export fn fibonacci_heap(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if ((input == null and length != 0) or length > 128) return -1;
    if (input) |values| { for (values[0..length]) |key| { if (key < -2147483648 or key > 2147483647) return -1; } }
    if (capacity < length * 8 or (output == null and length != 0)) return -2;
    if (length == 0) return 0;
    var nodes: [128]Node = undefined; for (&nodes) |*node| node.* = .{};
    var minimum: i32 = -1;
    for (0..length) |i| { nodes[i].key = input.?[i]; addRoot(&nodes, &minimum, @intCast(i)); }
    for (0..length) |out| {
        const z = minimum; storeLe(output.?, out * 8, nodes[@intCast(z)].key);
        const child = nodes[@intCast(z)].child;
        if (child != -1) { var children: [128]i32 = undefined; var child_count: usize = 0; var c = child; while (true) { children[child_count] = c; child_count += 1; c = nodes[@intCast(c)].right; if (c == child) break; } for (children[0..child_count]) |promoted| addRoot(&nodes, &minimum, promoted); }
        remove(&nodes, z);
        if (nodes[@intCast(z)].right == z) minimum = -1 else { minimum = nodes[@intCast(z)].right; consolidate(&nodes, &minimum); }
    }
    return @intCast(length * 8);
}
