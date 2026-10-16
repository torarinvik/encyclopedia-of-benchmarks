/// Apply the bounded Java EMAFilter recurrence to an integer sample stream.
fn put_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    unsafe { for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn ema_filter(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(2..=7).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (alpha_units, count_value) = (values[0], values[1]);
    if !(1..=1024).contains(&alpha_units) || !(0..=4).contains(&count_value) ||
        length != 2 + count_value as usize { return -1; }
    let count = count_value as usize;
    if values[2..].iter().any(|sample| !(-1_000_000..=1_000_000).contains(sample)) { return -1; }
    let required = count * 8;
    if output_capacity < required || (required > 0 && output.is_null()) { return -2; }

    let alpha = alpha_units as f64 / 1024.0;
    let mut ema_value = 0.0_f64;
    for index in 0..count {
        let sample = values[index + 2] as f64;
        if index == 0 { ema_value = sample; }
        else { ema_value = alpha * sample + (1.0 - alpha) * ema_value; }
        put_f64_le(output, index * 8, ema_value);
    }
    required as i64
}
