/// Terminal velocity with standard gravity and bounded positive inputs.
export fn terminal_velocity(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    const mass = values[0];
    const density = values[1];
    const area = values[2];
    const drag_coefficient = values[3];
    if (mass < 1 or mass > 1000 or density < 1 or density > 1000 or area < 1 or area > 1000 or
        drag_coefficient < 1 or drag_coefficient > 1000)
        return -1.0e300;
    const numerator = (2.0 * @as(f64, @floatFromInt(mass))) * 9.80665;
    const denominator = (@as(f64, @floatFromInt(density)) * @as(f64, @floatFromInt(area))) * @as(f64, @floatFromInt(drag_coefficient));
    return @sqrt(numerator / denominator);
}
