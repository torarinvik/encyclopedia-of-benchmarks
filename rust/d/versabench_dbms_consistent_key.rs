#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_consistent_key(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 || length > 17 || length != 16 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(raw, length) };
    for box_index in 0..2 {
        let base = box_index * 8;
        for d in 0..4 {
            let lower = values[base+d]; let upper = values[base+4+d];
            if !(-8..=8).contains(&lower) || !(-8..=8).contains(&upper) || lower > upper { return -1; }
        }
    }
    for d in 0..4 { if values[d] > values[12+d] || values[8+d] > values[4+d] { return 0; } }
    1
}
