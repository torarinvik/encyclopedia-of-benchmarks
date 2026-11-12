fn store_i64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn maximum_frequency_stack(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 130) return -1;
    const words = input.?;
    const count = words[0];
    if (count < 0 or count > 64 or length != 1 + 2 * @as(usize, @intCast(count))) return -1;
    var frequency = [_]i32{0} ** 17;
    var bucket_top = [_]i32{-1} ** 65;
    var node_value = [_]i64{0} ** 64;
    var node_next = [_]i32{-1} ** 64;
    var popped = [_]i64{0} ** 64;
    var nodes: usize = 0;
    var pop_count: usize = 0;
    var position: usize = 1;
    var maximum_frequency: usize = 0;
    for (0..@intCast(count)) |_| {
        const opcode = words[position];
        const argument = words[position + 1];
        position += 2;
        if (opcode == 0) {
            if (argument < -8 or argument > 8) return -1;
            const index: usize = @intCast(argument + 8);
            frequency[index] += 1;
            const level: usize = @intCast(frequency[index]);
            node_value[nodes] = argument;
            node_next[nodes] = bucket_top[level];
            bucket_top[level] = @intCast(nodes);
            nodes += 1;
            maximum_frequency = @max(maximum_frequency, level);
        } else if (opcode == 1 and argument == 0) {
            if (maximum_frequency == 0 or bucket_top[maximum_frequency] < 0) return -1;
            const node: usize = @intCast(bucket_top[maximum_frequency]);
            bucket_top[maximum_frequency] = node_next[node];
            const value = node_value[node];
            popped[pop_count] = value;
            pop_count += 1;
            frequency[@intCast(value + 8)] -= 1;
            if (bucket_top[maximum_frequency] < 0) maximum_frequency -= 1;
        } else return -1;
    }
    const needed = pop_count * 8;
    if (needed != 0 and (output == null or capacity < needed)) return -2;
    if (needed != 0) {
        for (0..pop_count) |i| store_i64(output.?, i * 8, popped[i]);
    }
    return @intCast(needed);
}
