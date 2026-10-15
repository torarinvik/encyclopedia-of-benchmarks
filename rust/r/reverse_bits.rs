/// Reverse the bit order of an unsigned 32-bit word.
#[no_mangle]
pub extern "C" fn reverse_bits(value: i64) -> i64 {
    if value < 0 || value > u32::MAX as i64 { return -1; }
    let mut remaining = value as u32;
    let mut reversed = 0u32;
    for _ in 0..32 {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    reversed as i64
}
