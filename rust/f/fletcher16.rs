/// Fletcher-16 checksum for bounded ASCII byte arrays.
const MAX_BYTES: usize = 4096;

#[no_mangle]
pub unsafe extern "C" fn fletcher16(input: *const i64, length: usize) -> i64 {
    if length > MAX_BYTES || (length != 0 && input.is_null()) { return -1; }
    let mut sum1 = 0u32;
    let mut sum2 = 0u32;
    for index in 0..length {
        let byte = *input.add(index);
        if !(0..=127).contains(&byte) { return -1; }
        sum1 = (sum1 + byte as u32) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    ((sum2 << 8) | sum1) as i64
}
