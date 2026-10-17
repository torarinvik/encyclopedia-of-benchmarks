const INVALID_RESULT: f64 = -1.0e300;

export fn transformations_2d(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return INVALID_RESULT;
    const operation = values[0];
    const parameter_micro = values[1];
    const component = values[2];
    if (operation < 0 or operation > 3 or component < 0 or component > 3) return INVALID_RESULT;

    var matrix: [4]f64 = undefined;
    if (operation == 0) {
        if (parameter_micro < -1_000_000 or parameter_micro > 1_000_000) return INVALID_RESULT;
        const factor = @as(f64, @floatFromInt(parameter_micro)) / 1_000_000.0;
        matrix = .{ factor * 1.0, factor * 0.0, factor * 0.0, factor * 1.0 };
    } else {
        if (parameter_micro < -6_283_185 or parameter_micro > 6_283_185) return INVALID_RESULT;
        const angle = @as(f64, @floatFromInt(parameter_micro)) / 1_000_000.0;
        const c = @cos(angle);
        const s = @sin(angle);
        if (operation == 1) {
            matrix = .{ c, -s, s, c };
        } else {
            const cs = c * s;
            if (operation == 2) {
                matrix = .{ c * c, cs, cs, s * s };
            } else {
                matrix = .{ 2.0 * c - 1.0, 2.0 * cs, 2.0 * cs, 2.0 * s - 1.0 };
            }
        }
    }
    return matrix[@intCast(component)];
}
