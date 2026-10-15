const MAX_NODES: usize = 1024;

export fn remove_duplicates_from_sorted_list(input: [*]const i64, length: usize,
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
    var current: usize = 0;
    while (current != length and next_node[current] != length) {
        const next = next_node[current];
        if (input[current] == input[next]) next_node[current] = next_node[next]
        else current = next;
    }
    var survivor_count: usize = 0;
    var node: usize = 0;
    while (node != length) { survivor_count += 1; node = next_node[node]; }
    const output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes) return -2;
    var written: usize = 0;
    node = 0;
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
