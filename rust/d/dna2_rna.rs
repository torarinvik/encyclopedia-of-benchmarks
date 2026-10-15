#[no_mangle]
pub unsafe extern "C" fn dna2_rna(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(1..=1001).contains(&length) || *values != 0 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let payload = &values[1..];
    if payload.iter().any(|&base| !(65..=90).contains(&base)) {
        return -1;
    }
    if output_capacity < payload.len() || (!payload.is_empty() && output.is_null()) {
        return -2;
    }
    for (index, &base) in payload.iter().enumerate() {
        *output.add(index) = if base == b'T' as i64 { b'U' } else { base as u8 };
    }
    payload.len() as i64
}
