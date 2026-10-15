const MAX_NODES: usize = 1024;

fn removeDuplicateRuns(input: [*]const i64, next_node: *[MAX_NODES + 1]usize,
    node: usize, none: usize) usize {
    if (node == none) return none;
    const next = next_node[node];
    if (next != none and input[node] == input[next]) {
        const duplicate = input[node];
        var after_run = next;
        while (after_run != none and input[after_run] == duplicate)
            after_run = next_node[after_run];
        return removeDuplicateRuns(input, next_node, after_run, none);
    }
    next_node[node] = removeDuplicateRuns(input, next_node, next, none);
    return node;
}

export fn remove_all_duplicates_from_sorted_list(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_NODES) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)
            or (index > 0 and input[index - 1] > value)) return -1;
    }
    var next_node: [MAX_NODES + 1]usize = undefined;
    for (0..length) |index| next_node[index] = index + 1;
    next_node[length] = length;
    const head = removeDuplicateRuns(input, &next_node, 0, length);
    var survivor_count: usize = 0;
    var node = head;
    while (node != length) { survivor_count += 1; node = next_node[node]; }
    const output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes) return -2;
    var written: usize = 0;
    node = head;
    while (node != length) {
        const bits: u32 = @bitCast(@as(i32, @intCast(input[node])));
        for (0..4) |byte| output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        written += 1;
        node = next_node[node];
    }
    if (written != survivor_count) return -1;
    return @intCast(written);
}

const std = @import("std");
