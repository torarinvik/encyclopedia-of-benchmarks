const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 5 * MAX_N;
const MAX_VALUE: i64 = 2;
const MAX_PASSES: i64 = 16;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s278_branch_recompute(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 7 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const passes_raw = values[1];
    if (n_raw < 1 or n_raw > MAX_N or passes_raw < 1 or passes_raw > MAX_PASSES) return -1;
    const n: usize = @intCast(n_raw);
    const passes: usize = @intCast(passes_raw);
    if (length != 2 + 5 * n) return -1;

    const a_start = 2;
    const b_start = a_start + n;
    const c_start = b_start + n;
    const d_start = c_start + n;
    const e_start = d_start + n;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[a_start + i];
        b[i] = values[b_start + i];
        c[i] = values[c_start + i];
        if (!boundedValue(a[i]) or !boundedValue(b[i]) or !boundedValue(c[i]) or
            !boundedValue(values[d_start + i]) or !boundedValue(values[e_start + i])) return -1;
    }
    if (output == null or output_capacity < 24 * n) return -2;

    for (0..passes) |_| {
        for (0..n) |i| {
            const de = values[d_start + i] * values[e_start + i];
            if (a[i] > 0) {
                c[i] = -c[i] + de;
            } else {
                b[i] = -b[i] + de;
            }
            a[i] = b[i] + c[i] * values[d_start + i];
        }
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, a[i]);
        storeI64Le(output, 8 * (n + i), b[i]);
        storeI64Le(output, 8 * (2 * n + i), c[i]);
    }
    return @intCast(3 * n);
}
