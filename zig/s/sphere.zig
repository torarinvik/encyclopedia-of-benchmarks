const INVALID_RESULT: f64 = -1.0e300;

pub export fn sphere(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 2) return INVALID_RESULT;
    const mode = input[0];
    const radius = input[1];
    if ((mode != 0 and mode != 1) or radius < 0 or radius > 1_000_000) return INVALID_RESULT;
    const r: f64 = @floatFromInt(radius);
    const r2 = r * r;
    if (mode == 0) return (((r2 * r) * 3.14159265358979323846) * 4.0) / 3.0;
    return (r2 * 3.14159265358979323846) * 4.0;
}
