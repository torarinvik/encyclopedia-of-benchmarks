const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_N: i64 = 30;

fn motzkinNumberValue(n: usize) i64 {
    var values: [31]i64 = @splat(0);
    values[0] = 1;
    if (n >= 1) values[1] = 1;
    var size: usize = 2;
    while (size <= n) : (size += 1) {
        var total = values[size - 1];
        var left: usize = 0;
        while (left < size - 1) : (left += 1) {
            total += values[left] * values[size - 2 - left];
        }
        values[size] = total;
    }
    return values[n];
}

fn solve(values: []const i64) i64 {
    if (values.len != 1 or values.len > MAX_PARSEABLE_LENGTH) return -1;
    const n = values[0];
    if (n < 0 or n > MAX_N) return -1;
    return motzkinNumberValue(@as(usize, @intCast(n)));
}

export fn motzkin_number(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input[0..length]);
}
