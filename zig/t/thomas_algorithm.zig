const max_n: usize = 32;

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn thomas_algorithm(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 1 + 4 * max_n) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 32) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 4 * n) return -1;

    const lower = input[1 .. 1 + n];
    const diagonal = input[1 + n .. 1 + 2 * n];
    const upper = input[1 + 2 * n .. 1 + 3 * n];
    const rhs = input[1 + 3 * n .. 1 + 4 * n];
    if (lower[0] != 0 or upper[n - 1] != 0) return -1;
    for (0..n) |row| {
        if (lower[row] < -16 or lower[row] > 16 or upper[row] < -16 or upper[row] > 16)
            return -1;
        if (diagonal[row] < 17 or diagonal[row] > 64 or rhs[row] < -1000 or rhs[row] > 1000)
            return -1;
        const lower_abs = if (lower[row] < 0) -lower[row] else lower[row];
        const upper_abs = if (upper[row] < 0) -upper[row] else upper[row];
        if (diagonal[row] <= lower_abs + upper_abs) return -1;
    }
    const output_bytes = n * 8;
    if (output_opt == null or capacity < output_bytes) return -2;

    var modified_upper = [_]f64{0} ** max_n;
    var modified_rhs = [_]f64{0} ** max_n;
    var solution = [_]f64{0} ** max_n;
    modified_upper[0] = @as(f64, @floatFromInt(upper[0])) /
        @as(f64, @floatFromInt(diagonal[0]));
    modified_rhs[0] = @as(f64, @floatFromInt(rhs[0])) /
        @as(f64, @floatFromInt(diagonal[0]));
    for (1..n) |row| {
        const pivot = @as(f64, @floatFromInt(diagonal[row])) -
            @as(f64, @floatFromInt(lower[row])) * modified_upper[row - 1];
        if (row + 1 < n) {
            modified_upper[row] = @as(f64, @floatFromInt(upper[row])) / pivot;
        }
        modified_rhs[row] = (@as(f64, @floatFromInt(rhs[row])) -
            @as(f64, @floatFromInt(lower[row])) * modified_rhs[row - 1]) / pivot;
    }
    solution[n - 1] = modified_rhs[n - 1];
    var row = n - 1;
    while (row > 0) {
        row -= 1;
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1];
    }
    const output = output_opt.?;
    for (0..n) |index| putF64Le(output, index * 8, solution[index]);
    return @intCast(output_bytes);
}
