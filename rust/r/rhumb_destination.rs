use std::f64::consts::PI;

const EARTH_RADIUS: f64 = 6_371_000.0;

#[no_mangle]
pub unsafe extern "C" fn rhumb_destination(input: *const f64, input_length: usize,
                                             output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, 4);
    let (latitude, longitude, distance, bearing) = (values[0], values[1], values[2], values[3]);
    if !latitude.is_finite() || !longitude.is_finite() || !distance.is_finite() || !bearing.is_finite() ||
        !(-80.0..=80.0).contains(&latitude) || !(-180.0..=180.0).contains(&longitude) ||
        !(0.0..=300_000.0).contains(&distance) || !(0.0..=360.0).contains(&bearing) { return -1; }
    let del = distance / EARTH_RADIUS;
    let phi1 = latitude * PI / 180.0;
    let lambda1 = longitude * PI / 180.0;
    let theta = bearing * PI / 180.0;
    let del_phi = del * theta.cos();
    let mut phi2 = phi1 + del_phi;
    if phi2 > PI / 2.0 { phi2 = PI / 2.0; }
    else if phi2 < -PI / 2.0 { phi2 = -PI / 2.0; }
    let del_psi = ((phi2 / 2.0 + PI / 4.0).tan() / (phi1 / 2.0 + PI / 4.0).tan()).ln();
    let q = if del_psi.abs() > 1e-12 { del_phi / del_psi } else { phi1.cos() };
    let del_lambda = del * theta.sin() / q;
    let result = [phi2 * 180.0 / PI, (lambda1 + del_lambda) * 180.0 / PI];
    if output.is_null() || output_capacity < 2 { return -2; }
    *output = result[0]; *output.add(1) = result[1];
    2
}
