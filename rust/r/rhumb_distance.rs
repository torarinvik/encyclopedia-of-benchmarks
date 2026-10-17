use std::f64::consts::PI;

const EARTH_RADIUS: f64 = 6_371_000.0;

#[no_mangle]
pub unsafe extern "C" fn rhumb_distance(input: *const f64, input_length: usize,
                                          output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, 4);
    let (lat1, long1, lat2, long2) = (values[0], values[1], values[2], values[3]);
    if !lat1.is_finite() || !long1.is_finite() || !lat2.is_finite() || !long2.is_finite() ||
        !(-85.0..=85.0).contains(&lat1) || !(-85.0..=85.0).contains(&lat2) ||
        !(-180.0..=180.0).contains(&long1) || !(-180.0..=180.0).contains(&long2) { return -1; }
    let phi1 = lat1 * PI / 180.0;
    let phi2 = lat2 * PI / 180.0;
    let del_phi = phi2 - phi1;
    let mut del_lambda = (long2 - long1) * PI / 180.0;
    if del_lambda > PI { del_lambda -= 2.0 * PI; }
    else if del_lambda < -PI { del_lambda += 2.0 * PI; }
    let del_psi = ((phi2 / 2.0 + PI / 4.0).tan() / (phi1 / 2.0 + PI / 4.0).tan()).ln();
    let q = if del_psi.abs() > 1e-12 { del_phi / del_psi } else { phi1.cos() };
    let distance = (del_phi.powf(2.0) + (q * del_lambda).powf(2.0)).sqrt() * EARTH_RADIUS;
    if output.is_null() || output_capacity < 1 { return -2; }
    *output = distance;
    1
}
