const MAX_N: usize = 8;
const MAX_ROUNDS: usize = 8;
const MAX_INPUT: usize = 259;

export fn freivalds_matrix_product_verification(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const rounds64 = input[1];
    if (n64 < 1 or n64 > 8 or rounds64 < 1 or rounds64 > 8) return -1;
    const n: usize = @intCast(n64);
    const rounds: usize = @intCast(rounds64);
    const matrix_words = n * n;
    if (length != 2 + 3 * matrix_words + rounds * n) return -1;
    for (2..2 + 3 * matrix_words) |word| {
        if (input[word] < -3 or input[word] > 3) return -1;
    }
    const signs_offset = 2 + 3 * matrix_words;
    for (signs_offset..length) |word| {
        if (input[word] != -1 and input[word] != 1) return -1;
    }

    var bx: [MAX_N]i64 = @splat(0);
    var abx: [MAX_N]i64 = @splat(0);
    var cx: [MAX_N]i64 = @splat(0);
    for (0..rounds) |round| {
        for (0..n) |row| {
            var sum: i64 = 0;
            for (0..n) |col| {
                sum += input[2 + matrix_words + row * n + col]
                    * input[signs_offset + round * n + col];
            }
            bx[row] = sum;
        }
        for (0..n) |row| {
            var left: i64 = 0;
            var right: i64 = 0;
            for (0..n) |col| {
                left += input[2 + row * n + col] * bx[col];
                right += input[2 + 2 * matrix_words + row * n + col]
                    * input[signs_offset + round * n + col];
            }
            abx[row] = left;
            cx[row] = right;
        }
        for (0..n) |row| {
            if (abx[row] != cx[row]) return 0;
        }
    }
    return 1;
}
