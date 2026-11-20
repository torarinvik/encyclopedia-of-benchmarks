const MAX_DIMENSION: usize = 8;
const MAX_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = -9223372036854775808;

fn bitCount(value: usize) usize {
    var remaining = value;
    var count: usize = 0;
    while (remaining != 0) {
        count += remaining & 1;
        remaining >>= 1;
    }
    return count;
}

export fn ryser_permanent(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > MAX_DIMENSION) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return INVALID_RESULT;

    for (0..n * n) |index| {
        if (input[1 + index] < -4 or input[1 + index] > 4) return INVALID_RESULT;
    }

    var row_sums = [_]i64{0} ** MAX_DIMENSION;
    var total: i64 = 0;
    var previous_gray: usize = 0;
    const subset_count = @as(usize, 1) << @intCast(n);
    for (0..subset_count) |ordinal| {
        const gray = ordinal ^ (ordinal >> 1);
        if (ordinal != 0) {
            const changed = gray ^ previous_gray;
            const column: usize = @intCast(@ctz(changed));
            const direction: i64 = if ((gray & changed) != 0) 1 else -1;
            for (0..n) |row| {
                row_sums[row] += direction * input[1 + row * n + column];
            }
        }

        var product: i64 = 1;
        for (0..n) |row| product *= row_sums[row];
        if (((n + bitCount(gray)) & 1) != 0) product = -product;
        total += product;
        previous_gray = gray;
    }
    return total;
}
