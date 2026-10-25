const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s132_shifted_row_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 8 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 2 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 2 + 3 * n) return -1;

    const row_start = 1;
    const target_start = row_start + n;
    const b_start = target_start + n;
    const c1_index = b_start + n;
    var target = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        target[i] = values[target_start + i];
        if (!boundedValue(values[row_start + i]) or !boundedValue(target[i]) or
            !boundedValue(values[b_start + i])) return -1;
    }
    const c1 = values[c1_index];
    if (!boundedValue(c1)) return -1;
    if (output == null or output_capacity < 8 * n) return -2;

    for (1..n) |i| {
        target[i] = values[row_start + i - 1] + values[b_start + i] * c1;
    }
    for (0..n) |i| storeI64Le(output, 8 * i, target[i]);
    return @intCast(n);
}
