/// Newton's second law: net force equals mass times acceleration.
export fn newtons_second_law_of_motion(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const mass = values[0];
    const acceleration = values[1];
    if (mass < -1000 or mass > 1000 or acceleration < -1000 or acceleration > 1000)
        return -1.0e300;
    return @as(f64, @floatFromInt(mass)) * @as(f64, @floatFromInt(acceleration));
}
