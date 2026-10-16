/// Portable byte-channel negative transform.
#[no_mangle]
pub unsafe extern "C" fn convert_to_negative(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || !(1..=4096).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let count = values[0];
    if !(0..=4095).contains(&count) || count as usize != length - 1 { return -1; }
    let channels = &values[1..];
    if channels.iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    let count = count as usize;
    if count > output_capacity || (count != 0 && output.is_null()) { return -2; }
    if count == 0 { return 0; }
    let output = std::slice::from_raw_parts_mut(output, count);
    for (destination, &channel) in output.iter_mut().zip(channels) {
        *destination = (255 - channel) as u8;
    }
    count as i64
}
