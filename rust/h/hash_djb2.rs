const MAX_BYTES: usize = 3;

/// Hash packed ASCII bytes with the 64-bit DJB2 recurrence.
#[no_mangle]
pub unsafe extern "C" fn hash_djb2(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_BYTES + 1 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let count_value = packed[0];
    if count_value < 0 || count_value > MAX_BYTES as i64 || length != count_value as usize + 1 {
        return -1;
    }
    let mut hash = 5381u64;
    for &byte in &packed[1..] {
        if byte < 1 || byte > 127 { return -1; }
        hash = hash * 33 + byte as u64;
    }
    hash as i64
}
