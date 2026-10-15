#[no_mangle]
pub extern "C" fn xs3_conversion(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length != 2 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let direction = packed[0];
    let mut value = packed[1];
    if direction == 0 {
        if !(0..=2_147_483_647).contains(&value) {
            return -1;
        }
        let mut decoded = 0_i64;
        let mut multiplier = 1_i64;
        while value > 0 {
            let nibble = value & 0xF;
            if !(3..=12).contains(&nibble) {
                return -1;
            }
            decoded += (nibble - 3) * multiplier;
            multiplier *= 10;
            value >>= 4;
        }
        return decoded;
    }
    if direction == 1 {
        if !(0..=9_999_999).contains(&value) {
            return -1;
        }
        let mut encoded = 0_i64;
        let mut shift = 0_u32;
        while value > 0 {
            let digit = value % 10 + 3;
            encoded |= digit << (shift * 4);
            value /= 10;
            shift += 1;
        }
        return encoded;
    }
    -1
}
