const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;
const MAX_PASSES: i64 = 32;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s131_forward_neighbor_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const passes_raw = values[1];
    if (n_raw < 1 or n_raw > MAX_N or passes_raw < 1 or passes_raw > MAX_PASSES) return -1;
    const n: usize = @intCast(n_raw);
    const passes: usize = @intCast(passes_raw);
    if (length != 2 + 2 * n) return -1;

    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        if (!boundedValue(a[i]) or !boundedValue(b[i])) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    for (0..passes) |_| {
        for (0..n - 1) |i| a[i] = a[i + 1] + b[i];
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
