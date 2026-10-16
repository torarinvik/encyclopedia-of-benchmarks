const MAX_LENGTH: usize = 100_001;
const POLYNOMIAL: i64 = 3_988_292_384;
const INITIAL: i64 = 4_294_967_295;
#[no_mangle]
pub unsafe extern "C" fn crc32(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut crc = INITIAL;
    for &byte in values {
        if !(0..=255).contains(&byte) { return -1; }
        crc ^= byte;
        for _ in 0..8 {
            crc = if (crc & 1) != 0 { (crc >> 1) ^ POLYNOMIAL } else { crc >> 1 };
        }
    }
    crc ^ INITIAL
}
