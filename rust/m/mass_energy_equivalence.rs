/// Mass-energy equivalence, with an operation selector for both source APIs.
const SPEED_OF_LIGHT: f64 = 299792458.0;
const SPEED_OF_LIGHT_SQUARED: f64 = SPEED_OF_LIGHT * SPEED_OF_LIGHT;

#[no_mangle]
pub extern "C" fn mass_energy_equivalence(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let (operation, value) = unsafe { (*values, *values.add(1)) };
    if (operation != 0 && operation != 1) || value < 0 || value > 1_000_000_000 {
        return -1.0e300;
    }
    if operation == 0 { return value as f64 * SPEED_OF_LIGHT_SQUARED; }
    value as f64 / SPEED_OF_LIGHT_SQUARED
}
