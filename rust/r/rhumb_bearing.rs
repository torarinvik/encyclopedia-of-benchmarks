use std::f64::consts::PI;

#[no_mangle]
pub unsafe extern "C" fn rhumb_bearing(input: *const f64, input_length: usize,
                                          output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, 4);
    let (lat1, long1, lat2, long2) = (values[0], values[1], values[2], values[3]);
    if !lat1.is_finite() || !long1.is_finite() || !lat2.is_finite() || !long2.is_finite() ||
        !(-85.0..=85.0).contains(&lat1) || !(-85.0..=85.0).contains(&lat2) ||
        !(-180.0..=180.0).contains(&long1) || !(-180.0..=180.0).contains(&long2) { return -1; }

    let phi1 = lat1 * PI / 180.0;
    let phi2 = lat2 * PI / 180.0;
    let mut del_lambda = (long2 - long1) * PI / 180.0;
    if del_lambda > PI { del_lambda -= 2.0 * PI; }
    else if del_lambda < -PI { del_lambda += 2.0 * PI; }
    let del_psi = ((phi2 / 2.0 + PI / 4.0).tan() / (phi1 / 2.0 + PI / 4.0).tan()).ln();
    let bearing = del_lambda.atan2(del_psi) * 180.0 / PI;
    let normalized = (bearing + 360.0) % 360.0;

    if output.is_null() || output_capacity < 1 { return -2; }
    *output = normalized;
    1
}
