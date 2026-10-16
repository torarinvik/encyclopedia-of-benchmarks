/// Buoyant force: fluid density * gravity * displaced volume.
export fn archimedes_principle_of_buoyant_force(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return -1.0e300;
    const fluid_density = values[0];
    const volume = values[1];
    if (fluid_density < 1 or fluid_density > 1000 or volume < 1 or volume > 1000)
        return -1.0e300;
    return (@as(f64, @floatFromInt(fluid_density)) * 9.80665) * @as(f64, @floatFromInt(volume));
}
