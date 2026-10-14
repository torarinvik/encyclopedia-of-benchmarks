/// Convert most-significant-first binary digits to a signed 64-bit decimal value.
#[no_mangle]
pub extern "C" fn binary_to_decimal(bits: *const i64, length: usize) -> i64 {
    if bits.is_null() || length == 0 || length > 63 {
        return -1;
    }
    let bits = unsafe { std::slice::from_raw_parts(bits, length) };
    let mut value = 0_u64;
    for &bit in bits {
        if bit != 0 && bit != 1 {
            return -1;
        }
        value = value * 2 + bit as u64;
    }
    value as i64
}
