const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_N: i64 = 30;

fn riordanNumberValue(n: usize) i64 {
    var values: [31]i64 = @splat(0);
    values[0] = 1;
    var size: usize = 2;
    while (size <= n) : (size += 1) {
        const size_i64: i64 = @intCast(size);
        values[size] = (size_i64 - 1) * (2 * values[size - 1] + 3 * values[size - 2])
                       / (size_i64 + 1);
    }
    return values[n];
}

fn solve(values: []const i64) i64 {
    if (values.len != 1 or values.len > MAX_PARSEABLE_LENGTH) return -1;
    const n = values[0];
    if (n < 0 or n > MAX_N) return -1;
    return riordanNumberValue(@as(usize, @intCast(n)));
}

export fn riordan_number(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input[0..length]);
}
