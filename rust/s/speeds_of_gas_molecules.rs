const MAX_INPUT_LENGTH: usize = 4;
const MAX_TEMPERATURE_MK: i64 = 1_000_000;
const MAX_MOLAR_MASS_MICRO: i64 = 1_000_000_000;
const GAS_CONSTANT: f64 = 8.31446261815324;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn speeds_of_gas_molecules(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let temperature_mk = values[1];
    let molar_mass_micro = values[2];
    if length != 3 || !(0..=1).contains(&operation) ||
        !(0..=MAX_TEMPERATURE_MK).contains(&temperature_mk) ||
        !(1..=MAX_MOLAR_MASS_MICRO).contains(&molar_mass_micro) { return INVALID_RESULT; }

    let temperature = temperature_mk as f64 / 1000.0;
    let molar_mass = molar_mass_micro as f64 / 1_000_000.0;
    if operation == 0 {
        ((8.0 * GAS_CONSTANT * temperature) / (PI_VALUE * molar_mass)).powf(0.5)
    } else {
        ((2.0 * GAS_CONSTANT * temperature) / molar_mass).powf(0.5)
    }
}
