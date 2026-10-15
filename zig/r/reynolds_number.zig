/// Reynolds number: density * abs(velocity) * diameter / viscosity.
export fn reynolds_number(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    const density = values[0];
    const velocity = values[1];
    const diameter = values[2];
    const viscosity = values[3];
    if (density < 1 or density > 1000 or velocity < -1000 or velocity > 1000 or
        diameter < 1 or diameter > 1000 or viscosity < 1 or viscosity > 1000)
        return -1.0e300;
    const speed = if (velocity < 0) -velocity else velocity;
    return (((@as(f64, @floatFromInt(density)) * @as(f64, @floatFromInt(speed))) *
        @as(f64, @floatFromInt(diameter))) / @as(f64, @floatFromInt(viscosity)));
}
