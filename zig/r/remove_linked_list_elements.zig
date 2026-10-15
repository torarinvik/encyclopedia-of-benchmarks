const MAX_NODES: usize = 1024;

fn removeChain(input: [*]const i64, next_node: *[MAX_NODES + 1]usize,
    node: usize, none: usize, target: i64) usize {
    if (node == none) return none;
    const next = next_node[node];
    if (input[node + 1] == target) return removeChain(input, next_node, next, none, target);
    next_node[node] = removeChain(input, next_node, next, none, target);
    return node;
}

export fn remove_linked_list_elements(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > MAX_NODES + 1) return -1;
    const target = input[0];
    if (target < std.math.minInt(i32) or target > std.math.maxInt(i32)) return -1;
    const node_count = length - 1;
    var next_node: [MAX_NODES + 1]usize = undefined;
    for (0..node_count) |index| {
        const value = input[index + 1];
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return -1;
        next_node[index] = index + 1;
    }
    next_node[node_count] = node_count;
    const head = removeChain(input, &next_node, if (node_count == 0) node_count else 0, node_count, target);
    var survivor_count: usize = 0;
    var node = head;
    while (node != node_count) { survivor_count += 1; node = next_node[node]; }
    const output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes) return -2;
    var written: usize = 0;
    node = head;
    while (node != node_count) {
        const bits: u32 = @bitCast(@as(i32, @intCast(input[node + 1])));
        for (0..4) |byte| output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        written += 1;
        node = next_node[node];
    }
    return @intCast(written);
}

const std = @import("std");
