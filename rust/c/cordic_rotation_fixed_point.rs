const OUTPUT_BYTES: usize = 24;
const ANGLES: [i64; 15] = [
    785398163, 463647609, 244978663, 124354995, 62418810,
    31239833, 15623729, 7812341, 3906230, 1953123,
    976562, 488281, 244141, 122070, 61035,
];

fn shift_floor(value: i64, shift: u32) -> i64 {
    if shift == 0 { return value; }
    let divisor = 1_i64 << shift;
    if value >= 0 { value / divisor } else { -((-value + divisor - 1) / divisor) }
}

fn write_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn cordic_rotation_fixed_point(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=3).contains(&length) { return -1; }
    if length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let angle = input[0];
    let stages = input[1];
    if !(-3_141_592_653..=3_141_592_653).contains(&angle) || !(1..=16).contains(&stages) {
        return -1;
    }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let (mut x, mut y, mut z) = (1_000_000_000_i64, 0_i64, angle);
    let mut direction = if z >= 0 { 1 } else { -1 };
    if direction > 0 { let old_x = x; x = -y; y = old_x; }
    else { let old_x = x; x = y; y = -old_x; }
    z -= direction * 1_570_796_327;
    for shift in 0..(stages as usize - 1) {
        direction = if z >= 0 { 1 } else { -1 };
        let (old_x, old_y) = (x, y);
        x = old_x - direction * shift_floor(old_y, shift as u32);
        y = old_y + direction * shift_floor(old_x, shift as u32);
        z -= direction * ANGLES[shift];
    }

    let mut staged = [0_u8; OUTPUT_BYTES];
    let scale = 1_000_000_000.0;
    write_f64_le(&mut staged, 0, x as f64 / scale);
    write_f64_le(&mut staged, 8, y as f64 / scale);
    write_f64_le(&mut staged, 16, z as f64 / scale);
    std::slice::from_raw_parts_mut(output, OUTPUT_BYTES).copy_from_slice(&staged);
    OUTPUT_BYTES as i64
}
