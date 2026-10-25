// Clean-room port of TSVC s281; see the package README for provenance and rights.

const MAX_N: i64 = 16;
const MAX_INPUT_LENGTH: usize = 50;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

pub export fn tsvc_s281_reverse_coupled_update(input: [*c]const i64,
    input_length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 5 or input_length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const passes_value = input[1];
    if (n_value < 1 or n_value > MAX_N or passes_value < 1 or passes_value > 8) return -1;
    const n: usize = @intCast(n_value);
    const passes: usize = @intCast(passes_value);
    if (input_length != 2 + 3 * n) return -1;

    var a = [_]f64{0.0} ** 16;
    var b = [_]f64{0.0} ** 16;
    var c_values = [_]f64{0.0} ** 16;
    for (0..n) |i| {
        const av = input[2 + i];
        const bv = input[2 + n + i];
        const cv = input[2 + 2 * n + i];
        if (av < -2 or av > 2 or bv < -2 or bv > 2 or cv < -1 or cv > 1) return -1;
        a[i] = @floatFromInt(av);
        b[i] = @floatFromInt(bv);
        c_values[i] = @floatFromInt(cv);
    }

    const output_bytes = 16 * n;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..passes) |_| {
        for (0..n) |i| {
            const x = a[n - i - 1] + b[i] * c_values[i];
            a[i] = x - 1.0;
            b[i] = x;
        }
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, @intFromFloat(a[i]));
        storeI64Le(output, 8 * (n + i), @intFromFloat(b[i]));
    }
    return @intCast(output_bytes);
}
