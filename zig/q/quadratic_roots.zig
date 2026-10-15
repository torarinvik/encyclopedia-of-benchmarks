const COEFFICIENT_LIMIT: i64 = 1_000_000;

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn quadratic_roots(
    values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize,
) i64 {
    if (values == null or length != 3) return -1;
    const ai = values[0];
    const bi = values[1];
    const ci = values[2];
    if (ai == 0 or ai < -COEFFICIENT_LIMIT or ai > COEFFICIENT_LIMIT or
        bi < -COEFFICIENT_LIMIT or bi > COEFFICIENT_LIMIT or
        ci < -COEFFICIENT_LIMIT or ci > COEFFICIENT_LIMIT) return -1;

    const a: f64 = @floatFromInt(ai);
    const b: f64 = @floatFromInt(bi);
    const c: f64 = @floatFromInt(ci);
    const discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return 0;

    if (discriminant == 0.0) {
        if (output == null or output_capacity < 8) return -2;
        writeF64Le(output, 0, -b / (2.0 * a));
        return 1;
    }

    if (output == null or output_capacity < 16) return -2;
    const square_root = @sqrt(discriminant);
    writeF64Le(output, 0, (-b + square_root) / (2.0 * a));
    writeF64Le(output, 8, (-b - square_root) / (2.0 * a));
    return 2;
}

