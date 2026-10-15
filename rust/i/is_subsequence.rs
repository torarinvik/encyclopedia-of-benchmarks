/// Check a Unicode scalar subsequence using a greedy forward scan.
const MAX_SEQUENCE_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 8194;

fn is_unicode_scalar(value: i64) -> bool {
    (0..=1_114_111).contains(&value) && !(55_296..=57_343).contains(&value)
}

#[no_mangle]
pub extern "C" fn is_subsequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PACKED_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_SEQUENCE_LENGTH as i64 ||
        values[1] < 0 || values[1] > MAX_SEQUENCE_LENGTH as i64 { return -1; }
    let main_length = values[0] as usize;
    let subsequence_length = values[1] as usize;
    if length != 2 + main_length + subsequence_length { return -1; }
    if values[2..].iter().any(|&value| !is_unicode_scalar(value)) { return -1; }

    let subsequence_start = 2 + main_length;
    let mut main_index = 0;
    let mut subsequence_index = 0;
    while subsequence_index < subsequence_length && main_index < main_length {
        if values[subsequence_start + subsequence_index] == values[2 + main_index] { subsequence_index += 1; }
        main_index += 1;
    }
    if subsequence_index == subsequence_length { 1 } else { 0 }
}
