const MAX_INPUT_VALUES: usize = 1001;

#[no_mangle]
pub unsafe extern "C" fn rna_transcription(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(1..=MAX_INPUT_VALUES).contains(&length) || *values != 0 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let payload = &values[1..];
    if payload.iter().any(|&base| !matches!(base, 65 | 67 | 71 | 84)) {
        return -1;
    }
    if output_capacity < payload.len() || (!payload.is_empty() && output.is_null()) {
        return -2;
    }
    for (index, &base) in payload.iter().enumerate() {
        *output.add(index) = match base {
            65 => b'U',
            67 => b'G',
            71 => b'C',
            _ => b'A',
        };
    }
    payload.len() as i64
}
