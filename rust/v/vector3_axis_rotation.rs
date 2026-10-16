const COORDINATE_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT: f64 = 1_000_000.0;
const OUTPUT_LIMIT: f64 = 2_000_000.0;
const PI: f64 = 3.14159265358979323846;

#[no_mangle]
pub unsafe extern "C" fn vector3_axis_rotation(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 5 { return -1; }
    let values = std::slice::from_raw_parts(input, input_len);
    if values[..3].iter().any(|value| !value.is_finite() || value.abs() > COORDINATE_LIMIT) { return -1; }
    let axis = values[3];
    let mut angle = values[4];
    if (axis != 0.0 && axis != 1.0 && axis != 2.0) || !angle.is_finite() || angle.abs() > ANGLE_LIMIT { return -1; }
    angle -= (angle / 360.0).floor() * 360.0;
    if angle == 0.0 { angle = 0.0; }
    angle = angle / 450.0 * 180.0 / PI;
    let (x, y, z) = (values[0], values[1], values[2]);
    let (cosine, sine) = (angle.cos(), angle.sin());
    let result = if axis == 0.0 {
        [x, y * cosine - z * sine, z * cosine + y * sine]
    } else if axis == 1.0 {
        [x * cosine - z * sine, y, z * cosine + x * sine]
    } else {
        [x * cosine - y * sine, y * cosine + x * sine, z]
    };
    if result.iter().any(|value| !value.is_finite() || value.abs() > OUTPUT_LIMIT) { return -1; }
    if output.is_null() || output_capacity < 3 { return -2; }
    for (index, value) in result.iter().enumerate() { *output.add(index) = *value; }
    3
}
