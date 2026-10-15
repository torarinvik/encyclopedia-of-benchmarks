const MAX_COORDINATE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn distance_between_two_points(values: [*]const i64, length: usize) f64 {
    if (length != 4) return INVALID_RESULT;
    for (0..4) |index| {
        if (values[index] < -MAX_COORDINATE or values[index] > MAX_COORDINATE) return INVALID_RESULT;
    }
    const dx: f64 = @floatFromInt(values[2] - values[0]);
    const dy: f64 = @floatFromInt(values[3] - values[1]);
    return @sqrt(dx * dx + dy * dy);
}
