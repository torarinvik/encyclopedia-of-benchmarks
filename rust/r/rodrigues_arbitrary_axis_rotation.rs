const COMPONENT_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT: f64 = 6.283185307179586;
const OUTPUT_LIMIT: f64 = 2_000_000.0;

#[no_mangle]
pub unsafe extern "C" fn rodrigues_arbitrary_axis_rotation(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 7 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_len) };
    if values[..6].iter().any(|value| !value.is_finite() || value.abs() > COMPONENT_LIMIT) {
        return -1;
    }
    let theta = values[6];
    if !theta.is_finite() || theta.abs() > ANGLE_LIMIT {
        return -1;
    }
    let scale = values[0].abs().max(values[1].abs()).max(values[2].abs());
    if scale == 0.0 {
        return -1;
    }
    let qx = values[0] / scale;
    let qy = values[1] / scale;
    let qz = values[2] / scale;
    let norm = ((qx * qx + qy * qy) + qz * qz).sqrt();
    if !norm.is_finite() || norm == 0.0 {
        return -1;
    }
    let (nx, ny, nz) = (qx / norm, qy / norm, qz / norm);
    let (vx, vy, vz) = (values[3], values[4], values[5]);
    let (cosine, sine) = (theta.cos(), theta.sin());
    let one_minus_cosine = 1.0 - cosine;
    let (cx, cy, cz) = (
        ny * vz - nz * vy,
        nz * vx - nx * vz,
        nx * vy - ny * vx,
    );
    let dot = (nx * vx + ny * vy) + nz * vz;
    let result = [
        (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine,
        (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine,
        (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine,
    ];
    if result.iter().any(|value| !value.is_finite() || value.abs() > OUTPUT_LIMIT) {
        return -1;
    }
    if output.is_null() || output_capacity < 3 {
        return -2;
    }
    for (index, value) in result.iter().enumerate() {
        unsafe { *output.add(index) = *value; }
    }
    3
}
