const INVALID_RESULT: f64 = -1.0e300;

pub export fn circular_arc(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 3) return INVALID_RESULT;
    const mode = input[0];
    const radius = input[1];
    const degrees = input[2];
    if ((mode != 0 and mode != 1) or radius < -1_000_000 or radius > 1_000_000 or degrees < -360_000 or degrees > 360_000) return INVALID_RESULT;
    const angle = @as(f64, @floatFromInt(degrees)) * (3.14159265358979323846 / 180.0);
    if (mode == 0) return @as(f64, @floatFromInt(radius)) * angle;
    return @as(f64, @floatFromInt(radius * radius)) * angle / 2.0;
}
