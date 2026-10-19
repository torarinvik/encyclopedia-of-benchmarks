const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const ELEMENT_COUNT: usize = 5000;
const MAX_OUTPUT_BYTES: usize = 700;
const Node = struct { value: i32, left: i32, right: i32 };
fn nextRandom(seed: *i64) i32 { seed.* = (seed.* * 1309 + 13849) & 65535; return @intCast(seed.*); }
fn validateTree(nodes: *const [ELEMENT_COUNT]Node, root: usize) bool {
    const node = nodes[root];
    if (node.left != -1) { const child = nodes[@intCast(node.left)]; if (child.value <= node.value or !validateTree(nodes, @intCast(node.left))) return false; }
    if (node.right != -1) { const child = nodes[@intCast(node.right)]; if (child.value >= node.value or !validateTree(nodes, @intCast(node.right))) return false; }
    return true;
}
fn buildAndCheckPass(selected_run: usize) struct { value: i32, valid: bool } {
    var values: [ELEMENT_COUNT]i32 = undefined;
    var nodes: [ELEMENT_COUNT]Node = undefined;
    var seed: i64 = 74755;
    for (0..ELEMENT_COUNT) |index| { const temp = nextRandom(&seed); values[index] = temp - @divTrunc(temp, 100000) * 100000 - 50000; }
    nodes[0] = .{ .value = values[0], .left = -1, .right = -1 };
    var used: usize = 1;
    for (1..ELEMENT_COUNT) |index| {
        var current: usize = 0;
        while (true) {
            const slot: *i32 = if (values[index] > nodes[current].value) &nodes[current].left else if (values[index] < nodes[current].value) &nodes[current].right else break;
            if (slot.* == -1) { slot.* = @intCast(used); nodes[used] = .{ .value = values[index], .left = -1, .right = -1 }; used += 1; break; }
            current = @intCast(slot.*);
        }
    }
    return .{ .value = values[selected_run + 1], .valid = validateTree(&nodes, 0) };
}
fn appendText(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, text: []const u8) void { for (text) |byte| { buffer[used.*] = byte; used.* += 1; } }
fn appendInteger(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value: i32) void {
    var remaining = value; if (remaining < 0) { buffer[used.*] = '-'; used.* += 1; remaining = -remaining; }
    var reverse: [12]u8 = undefined; var count: usize = 0;
    while (true) { reverse[count] = @intCast(48 + @mod(remaining, 10)); count += 1; remaining = @divTrunc(remaining, 10); if (remaining == 0) break; }
    while (count > 0) { count -= 1; buffer[used.*] = reverse[count]; used.* += 1; }
}
export fn stanford_treesort(runs: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (runs < MIN_RUNS or runs > MAX_RUNS) return -1;
    if (output_opt == null) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined; var used: usize = 0;
    for (0..@intCast(runs)) |run| { const item = buildAndCheckPass(run); appendInteger(&staged, &used, item.value); appendText(&staged, &used, "\n"); if (!item.valid) appendText(&staged, &used, " Error in Tree.\n"); }
    if (output_capacity < used) return -2;
    const output = output_opt.?; for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
