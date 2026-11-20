const MIN_COORDINATE: i64 = 900;
const MAX_COORDINATE: i64 = 1500;
const MAX_UPDATES: i64 = 8;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn roundNano(value: f64) i64 {
    const magnitude = if (value < 0.0) 0.0 - value else value;
    const rounded: i64 = @intFromFloat(@floor(magnitude * 1_000_000_000.0 + 0.5));
    return if (value < 0.0) -rounded else rounded;
}

export fn multidimensional_newton_raphson(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 4) return -1;
    if (length != 3) return -1;
    const values = input.?[0..length];
    const x_milli = values[0];
    const y_milli = values[1];
    const updates = values[2];
    if (x_milli < MIN_COORDINATE or x_milli > MAX_COORDINATE
            or y_milli < MIN_COORDINATE or y_milli > MAX_COORDINATE
            or updates < 1 or updates > MAX_UPDATES) return -1;
    if (output == null or capacity < 16) return -2;

    var x: f64 = @as(f64, @floatFromInt(x_milli)) / 1000.0;
    var y: f64 = @as(f64, @floatFromInt(y_milli)) / 1000.0;
    for (0..@intCast(updates)) |_| {
        const f1 = x * x + y - 3.0;
        const f2 = x + y * y - 3.0;
        const determinant = 4.0 * x * y - 1.0;
        const dx = (2.0 * y * f1 - f2) / determinant;
        const dy = (2.0 * x * f2 - f1) / determinant;
        x -= dx;
        y -= dy;
    }
    const bytes = output.?;
    storeI64Le(bytes, 0, roundNano(x));
    storeI64Le(bytes, 8, roundNano(y));
    return 16;
}
