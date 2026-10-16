const INVALID_RESULT: i64 = -1;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn xor_linked_list(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > 66) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 0 or count_value > 64 or length != @as(usize, @intCast(count_value)) + 1) {
        return INVALID_RESULT;
    }
    const count: usize = @intCast(count_value);
    for (values[1..]) |value| {
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
    }
    const needed = 8 + 8 * count;
    if (output == null or capacity < needed) return -2;
    const result = output.?[0..needed];

    var node_values: [65]i64 = @splat(0);
    var both: [65]usize = @splat(0);
    var tail: usize = 0;
    for (0..count) |i| {
        const node_id = i + 1;
        node_values[node_id] = values[i + 1];
        both[node_id] = tail;
        if (tail != 0) both[tail] ^= node_id;
        tail = node_id;
    }
    writeI64Le(result, 0, count_value);
    var out: usize = 8;
    var previous: usize = 0;
    var current: usize = if (count == 0) 0 else 1;
    while (current != 0) {
        writeI64Le(result, out, node_values[current]);
        out += 8;
        const next = previous ^ both[current];
        previous = current;
        current = next;
    }
    return @intCast(needed);
}
