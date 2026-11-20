//! Uncompiled indexed Calkin–Wilf fraction draft.
#[no_mangle]
pub unsafe extern "C" fn calkin_wilf_index(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let index = unsafe { *input };
    if !(1..(1i64 << 62)).contains(&index) { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let index = index as u64;
    let mut high = 1u64;
    while high <= index / 2 { high *= 2; }
    let (mut numerator, mut denominator) = (1u64, 1u64);
    high /= 2;
    while high != 0 {
        if index & high != 0 { numerator += denominator; } else { denominator += numerator; }
        high /= 2;
    }
    let bytes = unsafe { std::slice::from_raw_parts_mut(output, 16) };
    bytes[..8].copy_from_slice(&numerator.to_le_bytes());
    bytes[8..].copy_from_slice(&denominator.to_le_bytes());
    16
}
