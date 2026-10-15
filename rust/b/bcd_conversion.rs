const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn bcd_conversion(decimal: i64) -> i64 {
    if !(0..=9999).contains(&decimal) {
        return INVALID_RESULT;
    }
    let mut value = decimal;
    let mut bcd = 0i64;
    let mut shift = 0u32;
    while value > 0 {
        let digit = value % 10;
        bcd |= digit << (shift * 4);
        value /= 10;
        shift += 1;
    }
    bcd
}
