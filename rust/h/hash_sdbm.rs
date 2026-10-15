/// Hash ASCII byte arrays with the pinned 64-bit SDBM recurrence.
const MAX_BYTES: usize = 64;

fn signed_bits(value: u64) -> i64 {
    if value < (1u64 << 63) { value as i64 }
    else { i64::MIN + (value - (1u64 << 63)) as i64 }
}

#[no_mangle]
pub unsafe extern "C" fn hash_sdbm(input: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_BYTES || input.is_null() { return -1; }
    let bytes = std::slice::from_raw_parts(input, length);
    let mut hash = 0u64;
    for &byte in bytes {
        if byte < 1 || byte > 127 { return -1; }
        let value = byte as u64;
        hash = value.wrapping_add(hash.wrapping_shl(6))
            .wrapping_add(hash.wrapping_shl(16)).wrapping_sub(hash);
    }
    signed_bits(hash)
}
