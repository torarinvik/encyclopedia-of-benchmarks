const MAX_NODES: usize = 1024;
const std = @import("std");

// Delete the floor(n / 2)-indexed node using the source's fast/slow traversal.
export fn delete_middle_node(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_NODES) return -1;
    for (0..length) |index| {
        if (input[index] < std.math.minInt(i32) or input[index] > std.math.maxInt(i32)) return -1;
    }
    if (length <= 1) return 0;
    var next_node: [MAX_NODES + 1]usize = undefined;
    for (0..length) |index| next_node[index] = index + 1;
    next_node[length] = length;
    var node_count: usize = 0;
    var cursor: usize = 0;
    while (cursor != length) { node_count += 1; cursor = next_node[cursor]; }
    var fast: usize = 0;
    var slow: usize = 0;
    var previous = length;
    while (next_node[fast] != length and next_node[next_node[fast]] != length) {
        previous = slow;
        slow = next_node[slow];
        fast = next_node[next_node[fast]];
    }
    if (node_count % 2 == 0) { previous = slow; slow = next_node[slow]; }
    next_node[previous] = next_node[slow];
    const survivor_count = node_count - 1;
    const output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes) return -2;
    var written: usize = 0;
    var node: usize = 0;
    while (node != length) {
        const bits: u32 = @bitCast(@as(i32, @intCast(input[node])));
        for (0..4) |byte| output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        written += 1;
        node = next_node[node];
    }
    return @intCast(written);
}
