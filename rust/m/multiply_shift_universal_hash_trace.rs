const MAX_QUERIES: usize = 32;
const MAX_WORDS: usize = 2 + 2 * MAX_QUERIES;
const WORD_MASK: u64 = 0xffff_ffff;

#[no_mangle]
pub unsafe extern "C" fn multiply_shift_universal_hash_trace(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_WORDS + 1).contains(&length) { return -1; }
    let frame = std::slice::from_raw_parts(input, length);
    let width_value = frame[0];
    let count_value = frame[1];
    if !(1..=16).contains(&width_value) || !(0..=MAX_QUERIES as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }

    for pair in frame[2..].chunks_exact(2) {
        let multiplier = pair[0];
        let key = pair[1];
        if multiplier < 1 || multiplier > WORD_MASK as i64 || multiplier & 1 == 0 ||
            key < 0 || key > WORD_MASK as i64 { return -1; }
    }

    let required = count * 8;
    if (required > 0 && output.is_null()) || capacity < required { return -2; }
    let shift = 32 - width_value as u32;
    for query in 0..count {
        let multiplier = frame[2 + 2 * query] as u64;
        let key = frame[3 + 2 * query] as u64;
        let value = ((multiplier * key) & WORD_MASK) >> shift;
        let bytes = value.to_le_bytes();
        for (byte, part) in bytes.iter().enumerate() {
            output.add(query * 8 + byte).write(*part);
        }
    }
    required as i64
}
