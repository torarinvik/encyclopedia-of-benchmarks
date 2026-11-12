const max_n: usize = 16;
const max_input_values: usize = 1 + max_n * max_n;
const states: usize = 1 << max_n;
const modulus: i64 = 998244353;

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hafnian_of_matrix(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 2 or n_value > @as(i64, @intCast(max_n)) or @mod(n_value, 2) != 0) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var matrix: [max_n * max_n]i64 = @splat(0);
    for (0..n) |row| {
        for (0..n) |column| {
            const value = input[1 + row * n + column];
            if (value < 0 or value >= modulus or (row == column and value != 0)) return -1;
            matrix[row * max_n + column] = value;
        }
    }
    for (0..n) |row| {
        for (0..row) |column| {
            if (matrix[row * max_n + column] != matrix[column * max_n + row]) return -1;
        }
    }

    var dp: [states]i64 = @splat(0);
    dp[0] = 1;
    const full = (@as(usize, 1) << n) - 1;
    for (1..full + 1) |mask| {
        var bits = mask;
        var parity: usize = 0;
        while (bits > 0) : (bits /= 2) parity = (parity + bits % 2) % 2;
        if (parity != 0) continue;
        var first: usize = 0;
        while ((mask / (@as(usize, 1) << first)) % 2 == 0) : (first += 1) {}
        const without_first = mask - (@as(usize, 1) << first);
        for (first + 1..n) |second| {
            if ((without_first / (@as(usize, 1) << second)) % 2 == 0) continue;
            const rest = without_first - (@as(usize, 1) << second);
            dp[mask] = @mod(dp[mask] + matrix[first * max_n + second] * dp[rest], modulus);
        }
    }
    if (output_opt == null or capacity < 8) return -2;
    storeI64Le(output_opt.?, dp[full]);
    return 8;
}
