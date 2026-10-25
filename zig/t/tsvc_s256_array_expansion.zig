const MAX_N: usize = 16;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 2 + MAX_N + 2 * MAX_CELLS;
const MAX_A0: i64 = 1_000;
const MAX_FACTOR: i64 = 1_000;
const MAX_C0: i64 = 1_000_000;

fn store_i64_le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

/// Clean-room bounded port of TSVC s256; see package README for provenance.
export fn tsvc_s256_array_expansion(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const a0 = values[1];
    if (n_raw < 1 or n_raw > MAX_N or a0 < -MAX_A0 or a0 > MAX_A0) return -1;
    const n: usize = @intCast(n_raw);
    const cells = n * n;
    if (length != 2 + n + 2 * cells) return -1;
    const d_start = 2;
    const b_start = d_start + n;
    const c_start = b_start + cells;
    for (values[d_start..b_start]) |value| if (value < -MAX_FACTOR or value > MAX_FACTOR) return -1;
    for (values[b_start..c_start]) |value| if (value < -MAX_FACTOR or value > MAX_FACTOR) return -1;
    for (values[c_start..]) |value| if (value < -MAX_C0 or value > MAX_C0) return -1;

    const output_values = n + cells;
    if (output == null or output_capacity < output_values * 8) return -2;
    var a = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_CELLS;
    a[0] = a0;
    @memcpy(c[0..cells], values[c_start..]);
    for (0..n) |column| {
        for (1..n) |row| {
            a[row] = 1 - a[row - 1];
            const cell = row * n + column;
            c[cell] = a[row] + values[b_start + cell] * values[d_start + row];
        }
    }
    for (0..n) |row| store_i64_le(output, row * 8, a[row]);
    for (0..cells) |cell| store_i64_le(output, (n + cell) * 8, c[cell]);
    return @intCast(output_values);
}
