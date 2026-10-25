const MAX_N: usize = 64;
const MAX_PASSES: usize = 8;
const MAX_INPUT_LENGTH: usize = 2 + 4 * MAX_N;

fn store_i64_le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

/// Clean-room bounded port of TSVC s253; see package README for provenance.
export fn tsvc_s253_conditional_affine_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const passes_raw = values[1];
    if (n_raw < 1 or n_raw > MAX_N or passes_raw < 1 or passes_raw > MAX_PASSES) return -1;
    const n: usize = @intCast(n_raw);
    const passes: usize = @intCast(passes_raw);
    if (length != 2 + 4 * n) return -1;
    for (values[2..]) |value| if (value < -2 or value > 2) return -1;
    if (output == null or output_capacity < 16 * n) return -2;

    const a_start = 2;
    const b_start = a_start + n;
    const c_start = b_start + n;
    const d_start = c_start + n;
    var a = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    @memcpy(a[0..n], values[a_start..b_start]);
    @memcpy(c[0..n], values[c_start..d_start]);
    for (0..passes) |_| {
        for (0..n) |i| {
            const b_value = values[b_start + i];
            if (a[i] > b_value) {
                const updated = a[i] - b_value * values[d_start + i];
                c[i] += updated;
                a[i] = updated;
            }
        }
    }
    for (0..n) |i| {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), c[i]);
    }
    return @intCast(2 * n);
}
