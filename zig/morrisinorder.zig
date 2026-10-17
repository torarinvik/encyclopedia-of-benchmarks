const MAX_NODE_COUNT: usize = 63;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 65;

fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

/// Bounded Morris inorder traversal over a complete level-order tree.
export fn morrisinorder(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_NODE_COUNT) return -1;
    const count: usize = @intCast(raw_count);
    if (length != count + 1) return -1;
    for (0..count) |index| {
        const node = values[index + 1];
        if (node < -2147483648 or node > 2147483647) return -1;
    }

    const byte_count = 4 * count;
    if (output == null or output_capacity < byte_count) return -2;

    var left_nodes: [MAX_NODE_COUNT]i32 = @splat(-1);
    var right_nodes: [MAX_NODE_COUNT]i32 = @splat(-1);
    for (0..count) |index| {
        const left_index = 2 * index + 1;
        const right_index = 2 * index + 2;
        if (left_index < count) left_nodes[index] = @intCast(left_index);
        if (right_index < count) right_nodes[index] = @intCast(right_index);
    }

    var current: i32 = if (count == 0) -1 else 0;
    var written: usize = 0;
    while (current >= 0) {
        const current_index: usize = @intCast(current);
        if (left_nodes[current_index] < 0) {
            storeI32Le(output, 4 * written, @intCast(values[current_index + 1]));
            written += 1;
            current = right_nodes[current_index];
        } else {
            var predecessor: usize = @intCast(left_nodes[current_index]);
            while (right_nodes[predecessor] >= 0 and right_nodes[predecessor] != current)
                predecessor = @intCast(right_nodes[predecessor]);
            if (right_nodes[predecessor] < 0) {
                right_nodes[predecessor] = current;
                current = left_nodes[current_index];
            } else {
                right_nodes[predecessor] = -1;
                storeI32Le(output, 4 * written, @intCast(values[current_index + 1]));
                written += 1;
                current = right_nodes[current_index];
            }
        }
    }
    return @intCast(byte_count);
}
