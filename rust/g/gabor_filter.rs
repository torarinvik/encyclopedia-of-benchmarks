use std::ptr;

const PI: f64 = 3.14159265358979323846264338327950288;

unsafe fn put_f32_le(output: *mut u8, offset: usize, value: f64) {
    let bits = (value as f32).to_bits();
    for byte in 0..4 {
        output.add(offset + byte).write((bits >> (8 * byte)) as u8);
    }
}

#[no_mangle]
pub unsafe extern "C" fn gabor_filter(values: *const i64, length: usize,
                                        output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || length > 7 { return -1; }
    if length != 6 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let requested = values[0];
    let sigma = values[1];
    let theta = values[2];
    let wavelength = values[3];
    let gamma = values[4];
    let phase = values[5];
    if !(1..=7).contains(&requested) || !(1..=8).contains(&sigma) { return -1; }
    if !(0..=359).contains(&theta) || !(1..=8).contains(&wavelength) { return -1; }
    if !(0..=4).contains(&gamma) || !(-6..=6).contains(&phase) { return -1; }

    let mut side = requested as usize;
    if side % 2 == 0 { side += 1; }
    let output_bytes = side * side * 4;
    if output.is_null() || capacity < output_bytes { return -2; }

    let angle = (theta as f64 / 180.0) * PI;
    let cosine = angle.cos();
    let sine = angle.sin();
    let center = (side / 2) as isize;
    let mut offset = 0;
    for y in 0..side {
        let py = y as isize - center;
        for x in 0..side {
            let px = x as isize - center;
            let kernel_x = cosine * px as f64 + sine * py as f64;
            let kernel_y = -sine * px as f64 + cosine * py as f64;
            let exponent = -(kernel_x * kernel_x + (gamma * gamma) as f64 * kernel_y * kernel_y)
                / (2.0 * sigma as f64 * sigma as f64);
            let phase_angle = 2.0 * PI * kernel_x / wavelength as f64 + phase as f64;
            put_f32_le(output, offset, exponent.exp() * phase_angle.cos());
            offset += 4;
        }
    }
    output_bytes as i64
}
