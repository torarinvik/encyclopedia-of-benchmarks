/// Compute the Adler-32 checksum of a byte array.
#[no_mangle]
pub extern "C" fn adler32(values: *const i64, length: usize) -> i64 {
    if length > 100001 || (length != 0 && values.is_null()) {
        return -1;
    }
    if length == 0 {
        return 1;
    }

    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut a: u32 = 1;
    let mut b: u32 = 0;
    for &value in values {
        if !(0..=255).contains(&value) {
            return -1;
        }
        a = (a + value as u32) % 65521;
        b = (b + a) % 65521;
    }

    (((b << 16) | a) as u64) as i64
}
