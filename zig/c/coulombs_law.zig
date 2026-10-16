const COULOMBS_CONSTANT: f64 = 8.9875517923e9;
const MAX_CHARGE_MICROCOULOMBS: i64 = 1_000_000;
const MAX_DISTANCE_MILLIMETERS: i64 = 1_000_000;

pub export fn coulombs_law(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return -1.0e300;
    const charge1_value = values[0];
    const charge2_value = values[1];
    const distance_value = values[2];
    if (charge1_value == 0 or charge2_value == 0 or
        charge1_value < -MAX_CHARGE_MICROCOULOMBS or charge1_value > MAX_CHARGE_MICROCOULOMBS or
        charge2_value < -MAX_CHARGE_MICROCOULOMBS or charge2_value > MAX_CHARGE_MICROCOULOMBS or
        distance_value < 1 or distance_value > MAX_DISTANCE_MILLIMETERS) return -1.0e300;

    const charge1 = @as(f64, @floatFromInt(charge1_value)) / 1_000_000.0;
    const charge2 = @as(f64, @floatFromInt(charge2_value)) / 1_000_000.0;
    const distance = @as(f64, @floatFromInt(distance_value)) / 1_000.0;
    var charge_product = charge1 * charge2;
    if (charge_product < 0.0) charge_product = -charge_product;
    return COULOMBS_CONSTANT * charge_product / (distance * distance);
}
