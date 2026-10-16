const INVALID_RESULT: f64 = -1.0e300;
const COULOMBS_CONSTANT: f64 = 8.9875517923e9;
const MAX_CHARGE_MICROCOULOMBS: i64 = 1_000_000;
const MAX_DISTANCE_MILLIMETERS: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn coulombs_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 {
        return INVALID_RESULT;
    }
    let (charge1_value, charge2_value, distance_value) = unsafe {
        (*values, *values.add(1), *values.add(2))
    };
    if charge1_value == 0
        || charge2_value == 0
        || !(-MAX_CHARGE_MICROCOULOMBS..=MAX_CHARGE_MICROCOULOMBS).contains(&charge1_value)
        || !(-MAX_CHARGE_MICROCOULOMBS..=MAX_CHARGE_MICROCOULOMBS).contains(&charge2_value)
        || !(1..=MAX_DISTANCE_MILLIMETERS).contains(&distance_value)
    {
        return INVALID_RESULT;
    }

    let charge1 = charge1_value as f64 / 1_000_000.0;
    let charge2 = charge2_value as f64 / 1_000_000.0;
    let distance = distance_value as f64 / 1_000.0;
    let mut charge_product = charge1 * charge2;
    if charge_product < 0.0 {
        charge_product = -charge_product;
    }
    COULOMBS_CONSTANT * charge_product / (distance * distance)
}
