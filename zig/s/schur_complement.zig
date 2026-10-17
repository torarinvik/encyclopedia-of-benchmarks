const invalid_result: f64 = -1.0e300;

export fn schur_complement(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 6) return invalid_result;
    const a00, a01, a11, b0, b1, c00 = .{ input[0], input[1], input[2], input[3], input[4], input[5] };
    if (a00 < -8 or a00 > 8 or a01 < -8 or a01 > 8 or a11 < -8 or a11 > 8 or
        b0 < -100 or b0 > 100 or b1 < -100 or b1 > 100 or c00 < -100 or c00 > 100) return invalid_result;
    const determinant = a00 * a11 - a01 * a01;
    if (determinant == 0) return invalid_result;
    const inv00 = @as(f64, @floatFromInt(a11)) / @as(f64, @floatFromInt(determinant));
    const inv01 = -@as(f64, @floatFromInt(a01)) / @as(f64, @floatFromInt(determinant));
    const inv10 = -@as(f64, @floatFromInt(a01)) / @as(f64, @floatFromInt(determinant));
    const inv11 = @as(f64, @floatFromInt(a00)) / @as(f64, @floatFromInt(determinant));
    const left0 = @as(f64, @floatFromInt(b0)) * inv00 + @as(f64, @floatFromInt(b1)) * inv10;
    const left1 = @as(f64, @floatFromInt(b0)) * inv01 + @as(f64, @floatFromInt(b1)) * inv11;
    const quadratic = left0 * @as(f64, @floatFromInt(b0)) + left1 * @as(f64, @floatFromInt(b1));
    return @as(f64, @floatFromInt(c00)) - quadratic;
}
