const max_n: usize = 128;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cartesian_tree(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 1 + max_n) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > 128) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;

    var parent = [_]i64{0} ** max_n;
    var stack = [_]usize{0} ** max_n;
    for (0..n) |i| {
        const key = input[i + 1];
        if (key < 0 or key > 1_000_000_000) return -1;
        parent[i] = @intCast(i);
    }

    var stack_size: usize = 0;
    for (0..n) |i| {
        var last = max_n;
        while (stack_size > 0 and input[stack[stack_size - 1] + 1] > input[i + 1]) {
            stack_size -= 1;
            last = stack[stack_size];
        }
        if (stack_size > 0) parent[i] = @intCast(stack[stack_size - 1]);
        if (last < max_n) parent[last] = @intCast(i);
        stack[stack_size] = i;
        stack_size += 1;
    }

    const output_bytes = n * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..n) |i| storeI64Le(output, i * 8, parent[i]);
    return @intCast(output_bytes);
}
