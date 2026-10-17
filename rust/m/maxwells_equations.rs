use std::f64::consts::PI;

const INVALID: f64 = -1.0e300;
const MAX_PHYSICAL: i64 = 1_000_000_000_000_000;
const MAX_FLUX_RATE: i64 = 1_000_000_000_000_000_000;
const MIN_CONSTANT: i64 = 1_000_000;
const MAX_CONSTANT: i64 = 1_000_000_000_000_000;
const EPSILON_DEFAULT: f64 = 8.8541878128e-12;
const MU_DEFAULT: f64 = 4.0 * PI * 1e-7;

fn in_range(value: i64, limit: i64) -> bool { value >= -limit && value <= limit }
fn decode_constant(raw: i64, fallback: f64) -> Option<f64> {
    if raw == 0 { Some(fallback) }
    else if raw < MIN_CONSTANT || raw > MAX_CONSTANT { None }
    else { Some(raw as f64 / 1e18) }
}
fn law_result(actual: f64, expected: f64) -> f64 {
    let tolerance = if expected != 0.0 { 0.01 * expected.abs() } else { 1e-10 };
    if (actual - expected).abs() <= tolerance { 1.0 } else { 0.0 }
}

#[no_mangle]
pub unsafe extern "C" fn maxwells_equations(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 1 || length > 7 { return INVALID; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    match operation {
        0 => {
            if length != 5 { return INVALID; }
            let (field, area, charge, epsilon_raw) = (values[1], values[2], values[3], values[4]);
            if !in_range(field, MAX_PHYSICAL) || area < 0 || area > MAX_PHYSICAL || !in_range(charge, MAX_PHYSICAL) { return INVALID; }
            let Some(epsilon) = decode_constant(epsilon_raw, EPSILON_DEFAULT) else { return INVALID; };
            let electric_flux = (field as f64 / 1e12) * (area as f64 / 1e12);
            let expected_flux = (charge as f64 / 1e12) / epsilon;
            law_result(electric_flux, expected_flux)
        }
        1 => {
            if length != 3 || !in_range(values[1], MAX_PHYSICAL) || !in_range(values[2], MAX_PHYSICAL) { return INVALID; }
            let circulation = values[1] as f64 / 1e12;
            let expected = -(values[2] as f64 / 1e12);
            law_result(circulation, expected)
        }
        2 => {
            if length != 6 || !in_range(values[1], MAX_PHYSICAL) || !in_range(values[2], MAX_PHYSICAL) || !in_range(values[3], MAX_FLUX_RATE) { return INVALID; }
            let Some(mu) = decode_constant(values[4], MU_DEFAULT) else { return INVALID; };
            let Some(epsilon) = decode_constant(values[5], EPSILON_DEFAULT) else { return INVALID; };
            let displacement_current = epsilon * (values[3] as f64 / 1e6);
            let total_current = (values[2] as f64 / 1e12) + displacement_current;
            let expected = mu * total_current;
            law_result(values[1] as f64 / 1e12, expected)
        }
        3 | 4 => {
            if length != 3 { return INVALID; }
            let Some(mu) = decode_constant(values[1], MU_DEFAULT) else { return INVALID; };
            let Some(epsilon) = decode_constant(values[2], EPSILON_DEFAULT) else { return INVALID; };
            if operation == 3 { 1.0 / (mu * epsilon).sqrt() } else { (mu / epsilon).sqrt() }
        }
        5 => {
            if length != 4 || !in_range(values[1], MAX_PHYSICAL) || !in_range(values[2], MAX_PHYSICAL) { return INVALID; }
            let Some(mu) = decode_constant(values[3], MU_DEFAULT) else { return INVALID; };
            ((values[1] as f64 / 1e12) * (values[2] as f64 / 1e12)) / mu
        }
        6 => {
            if length != 5 || !in_range(values[1], MAX_PHYSICAL) || !in_range(values[2], MAX_PHYSICAL) { return INVALID; }
            let Some(epsilon) = decode_constant(values[3], EPSILON_DEFAULT) else { return INVALID; };
            let Some(mu) = decode_constant(values[4], MU_DEFAULT) else { return INVALID; };
            let electric = 0.5 * epsilon * (values[1] as f64 / 1e12).powi(2);
            let magnetic = 0.5 * (values[2] as f64 / 1e12).powi(2) / mu;
            electric + magnetic
        }
        _ => INVALID,
    }
}
