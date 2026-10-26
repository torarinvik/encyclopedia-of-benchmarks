/// Clean-room bounded digit-to-segment profile for the BEEBS lcdnum source.
const INPUT_BYTES: usize = 5;
const SEGMENT_MASKS: [u8; 16] = [
    0x00, 0x24, 0x5D, 0x6D, 0x2E, 0x5D, 0x7B, 0x25,
    0x7F, 0x6F, 0x3F, 0x7A, 0x53, 0x7C, 0x5B, 0x1B,
];

#[no_mangle]
pub unsafe extern "C" fn beebs_lcdnum(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length != INPUT_BYTES { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|value| !(0..=255).contains(value)) { return -1; }
    if output.is_null() || capacity < INPUT_BYTES { return -2; }
    let result = std::slice::from_raw_parts_mut(output, INPUT_BYTES);
    for (index, value) in input.iter().enumerate() {
        result[index] = SEGMENT_MASKS[(*value as u8) & 0x0F];
    }
    INPUT_BYTES as i64
}
