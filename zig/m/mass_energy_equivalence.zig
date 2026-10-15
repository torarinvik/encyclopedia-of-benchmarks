/// Mass-energy equivalence, with an operation selector for both source APIs.
const SPEED_OF_LIGHT: f64 = 299792458.0;
const SPEED_OF_LIGHT_SQUARED: f64 = SPEED_OF_LIGHT * SPEED_OF_LIGHT;

export fn mass_energy_equivalence(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const operation = values[0];
    const value = values[1];
    if ((operation != 0 and operation != 1) or value < 0 or value > 1000000000) return -1.0e300;
    if (operation == 0) return @as(f64, @floatFromInt(value)) * SPEED_OF_LIGHT_SQUARED;
    return @as(f64, @floatFromInt(value)) / SPEED_OF_LIGHT_SQUARED;
}
