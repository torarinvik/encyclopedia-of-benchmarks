const MAX_N: usize = 16;
const MAX_TRIANGLE: usize = MAX_N * (MAX_N + 1) / 2;
const MAX_INPUT_LENGTH: usize = 2 + MAX_TRIANGLE + MAX_N * MAX_N;
const MAX_VALUE: i64 = 1_000_000;
const MAX_ROUNDS: usize = 32;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s141_packed_symmetric_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const rounds_raw = values[1];
    if (n_raw < 1 or n_raw > MAX_N or rounds_raw < 1 or rounds_raw > MAX_ROUNDS) return -1;
    const n: usize = @intCast(n_raw);
    const rounds: usize = @intCast(rounds_raw);
    const triangle = n * (n + 1) / 2;
    const matrix_start = 2 + triangle;
    if (length != matrix_start + n * n) return -1;

    var packed = [_]i64{0} ** MAX_TRIANGLE;
    for (0..triangle) |p| {
        packed[p] = values[2 + p];
        if (!boundedValue(packed[p])) return -1;
    }
    for (0..n * n) |p| {
        if (!boundedValue(values[matrix_start + p])) return -1;
    }
    if (output == null or output_capacity < 8 * triangle) return -2;

    for (0..rounds) |_| {
        for (0..n) |i| {
            for (i..n) |j| {
                const k = j * (j + 1) / 2 + i;
                packed[k] += values[matrix_start + j * n + i];
            }
        }
    }
    for (0..triangle) |p| storeI64Le(output, 8 * p, packed[p]);
    return @intCast(triangle);
}
