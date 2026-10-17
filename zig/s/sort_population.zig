fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn sort_population(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 129 or input[0] < 1 or input[0] > 64) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    var costs: [64]i64 = undefined;
    var identifiers: [64]i64 = undefined;
    var seen = [_]bool{false} ** 64;
    for (0..count) |index| {
        const cost = input[1 + 2 * index];
        const identifier = input[2 + 2 * index];
        if (cost < -1000000 or cost > 1000000 or identifier < 0 or identifier >= @as(i64, @intCast(count))) return -1;
        const id: usize = @intCast(identifier);
        if (seen[id]) return -1;
        seen[id] = true;
        costs[index] = cost;
        identifiers[index] = identifier;
    }
    for (1..count) |index| {
        const key_cost = costs[index];
        const key_identifier = identifiers[index];
        var position = index;
        while (position > 0 and costs[position - 1] > key_cost) {
            costs[position] = costs[position - 1];
            identifiers[position] = identifiers[position - 1];
            position -= 1;
        }
        costs[position] = key_cost;
        identifiers[position] = key_identifier;
    }
    for (1..count) |index| if (costs[index - 1] == costs[index]) return -1;
    const output_length = count * 16;
    if (output == null or capacity < output_length) return -2;
    for (0..count) |index| {
        writeI64Le(output, index * 16, costs[index]);
        writeI64Le(output, index * 16 + 8, identifiers[index]);
    }
    return @intCast(output_length);
}
