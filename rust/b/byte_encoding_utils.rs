/// Reverse the eight bytes in a 64-bit bit pattern.
#[no_mangle]
pub extern "C" fn byte_encoding_utils(value: i64) -> i64 {
    value.swap_bytes()
}
