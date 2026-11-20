fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn hypercube_edge_monotonicity_tester(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const values = input.?;
    const n_value = values[0];
    const q_value = values[1];
    if (n_value < 1 or n_value > 6 or q_value < 1 or q_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    const domain = @as(usize, 1) << @as(u6, @intCast(n));
    if (length != 2 + domain + 2 * q) return -1;
    for (0..domain) |vertex| {
        if (values[2 + vertex] != 0 and values[2 + vertex] != 1) return -1;
    }
    const tape = 2 + domain;
    for (0..q) |round| {
        const vertex = values[tape + 2 * round];
        const coordinate = values[tape + 2 * round + 1];
        if (vertex < 0 or vertex >= @as(i64, @intCast(domain)) or coordinate < 0 or coordinate >= n_value) return -1;
    }
    var accepted: i64 = 1;
    var rounds: i64 = 0;
    for (0..q) |round| {
        const vertex: usize = @intCast(values[tape + 2 * round]);
        const coordinate: u6 = @intCast(values[tape + 2 * round + 1]);
        const bit = @as(usize, 1) << coordinate;
        const lower = vertex & ~bit;
        rounds += 1;
        if (values[2 + lower] > values[2 + (lower | bit)]) { accepted = 0; break; }
    }
    if (output == null or capacity < 24) return -2;
    const result = output.?;
    store_i64_le(result, 0, accepted);
    store_i64_le(result, 8, rounds);
    store_i64_le(result, 16, 2 * rounds);
    return 24;
}
