const MAX_ORDER: usize = 8;
const MAX_INPUT_WORDS: usize = 18;
const MOD: i64 = 1_000_000_007;
const MAX_N: i64 = 1_000_000_000_000;
const Matrix = struct { cell: [MAX_ORDER][MAX_ORDER]i64 };

fn zeroMatrix() Matrix {
    return .{ .cell = [_][MAX_ORDER]i64{[_]i64{0} ** MAX_ORDER} ** MAX_ORDER };
}
fn multiply(left: Matrix, right: Matrix, order: usize) Matrix {
    var result = zeroMatrix();
    for (0..order) |row| {
        for (0..order) |col| {
            for (0..order) |inner| {
                result.cell[row][col] = @mod(result.cell[row][col] + @mod(left.cell[row][inner] * right.cell[inner][col], MOD), MOD);
            }
        }
    }
    return result;
}
fn power(matrix: Matrix, exponent: i64, order: usize) Matrix {
    if (exponent == 1) return matrix;
    if (@mod(exponent, 2) == 1) return multiply(matrix, power(matrix, exponent - 1, order), order);
    const half = power(matrix, @divTrunc(exponent, 2), order);
    return multiply(half, half, order);
}

export fn matrix_exponentiation(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const order_raw = input[0];
    if (order_raw < 1 or order_raw > 8 or length != @as(usize, @intCast(2 * order_raw + 2))) return -1;
    const order: usize = @intCast(order_raw);
    for (0..2 * order) |i| if (input[1 + i] < 0 or input[1 + i] >= MOD) return -1;
    const n = input[2 * order + 1];
    if (n < 0 or n > MAX_N) return -1;
    if (n == 0) return 0;
    if (n <= order_raw) return input[@intCast(n)];
    var transition = zeroMatrix();
    for (0..(order - 1)) |i| transition.cell[i][i + 1] = 1;
    for (0..order) |col| transition.cell[order - 1][col] = input[2 * order - col];
    transition = power(transition, n - 1, order);
    var result: i64 = 0;
    for (0..order) |i| result = @mod(result + @mod(transition.cell[0][i] * input[1 + i], MOD), MOD);
    return result;
}
