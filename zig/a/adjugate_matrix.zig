const max_n: usize = 6;
const modulus: i64 = 998244353;

fn minorDeterminant(matrix: *const [max_n * max_n]i64, n: usize,
    skip_row: usize, skip_column: usize) i64 {
    const dimension = n - 1;
    if (dimension == 0) return 1;

    var minor = [_]i64{0} ** (max_n * max_n);
    var target_row: usize = 0;
    for (0..n) |row| {
        if (row == skip_row) continue;
        var target_column: usize = 0;
        for (0..n) |column| {
            if (column == skip_column) continue;
            minor[target_row * dimension + target_column] = matrix[row * n + column];
            target_column += 1;
        }
        target_row += 1;
    }

    var dp = [_]i64{0} ** (1 << (max_n - 1));
    dp[0] = 1;
    const limit = @as(usize, 1) << @intCast(dimension);
    for (0..limit) |mask| {
        const row: usize = @popCount(mask);
        if (row == dimension) continue;
        for (0..dimension) |column| {
            if ((mask & (@as(usize, 1) << @intCast(column))) != 0) continue;
            const greater_mask = mask >> @intCast(column + 1);
            const inversions = @popCount(greater_mask);
            const next = mask | (@as(usize, 1) << @intCast(column));
            const term = @mod(dp[mask] * minor[row * dimension + column], modulus);
            if (inversions & 1 == 0) {
                dp[next] = @mod(dp[next] + term, modulus);
            } else {
                dp[next] = @mod(dp[next] - term + modulus, modulus);
            }
        }
    }
    return dp[limit - 1];
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn adjugate_matrix(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 1 + max_n * max_n) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > max_n) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var matrix = [_]i64{0} ** (max_n * max_n);
    for (0..n * n) |index| {
        const value = input[1 + index];
        if (value < 0 or value >= modulus) return -1;
        matrix[index] = value;
    }

    const output_bytes = 8 * n * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..n) |row| {
        for (0..n) |column| {
            var value = minorDeterminant(&matrix, n, column, row);
            if ((row + column) & 1 != 0 and value != 0) value = modulus - value;
            storeI64Le(output, 8 * (row * n + column), value);
        }
    }
    return @intCast(output_bytes);
}
