const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 1_000_000;

export fn tsvc_s3111_positive_value_sum(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const n_raw = input[0];
    if (n_raw < 0 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + n) return -1;

    var sum: i64 = 0;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
        if (value > 0) sum += value;
    }
    return sum;
}
