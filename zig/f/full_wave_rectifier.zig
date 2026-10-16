/// Evaluate the six pinned full-wave rectifier helper formulas.
const OUTPUT_BYTES: i64 = 48;

fn store_f64_le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 255);
}

export fn full_wave_rectifier(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 5) return -1;
    const rf_i = values[0];
    const rs_i = values[1];
    const rl_i = values[2];
    const vm_i = values[3];
    const im_i = values[4];
    if (rf_i < 0 or rf_i > 1000000 or rs_i < 0 or rs_i > 1000000 or
        rl_i < 1 or rl_i > 1000000 or vm_i < -1000000 or vm_i > 1000000 or
        im_i < -1000000 or im_i > 1000000) return -1;
    if (output == null or output_capacity < 48) return -2;

    const rf: f64 = @floatFromInt(rf_i);
    const rs: f64 = @floatFromInt(rs_i);
    const rl: f64 = @floatFromInt(rl_i);
    const vm: f64 = @floatFromInt(vm_i);
    const im: f64 = @floatFromInt(im_i);
    store_f64_le(output, 0, vm / (rf + rs + rl));
    store_f64_le(output, 8, 2.0 * im * 0.318);
    store_f64_le(output, 16, 2.0 * 0.318 * vm);
    store_f64_le(output, 24, vm / rl);
    store_f64_le(output, 32, im * 0.707);
    store_f64_le(output, 40, vm * 0.707);
    return OUTPUT_BYTES;
}
