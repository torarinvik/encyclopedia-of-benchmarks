const SPEED_OF_LIGHT: i64 = 299_792_458;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn relativistic_kinetic_energy(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let mass = unsafe { *values };
    let velocity = unsafe { *values.add(1) };
    if !(0..=1_000_000).contains(&mass) || !(-(SPEED_OF_LIGHT - 1)..=SPEED_OF_LIGHT - 1).contains(&velocity) {
        return INVALID_RESULT;
    }
    let c_squared = SPEED_OF_LIGHT * SPEED_OF_LIGHT;
    let gamma = 1.0 / (1.0 - (velocity * velocity) as f64 / c_squared as f64).sqrt();
    (gamma - 1.0) * mass as f64 * c_squared as f64
}
