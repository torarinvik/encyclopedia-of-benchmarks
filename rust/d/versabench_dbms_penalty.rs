#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_penalty(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 || length > 17 || length != 16 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(raw, length) };
    for box_index in 0..2 {
        let at = box_index * 8;
        for d in 0..4 {
            let lo = v[at+d]; let hi = v[at+4+d];
            if !(-8..=8).contains(&lo) || !(-8..=8).contains(&hi) || lo >= hi { return -1; }
        }
    }
    let mut joined = 1_i64; let mut original = 1_i64;
    for d in 0..4 {
        joined *= v[4+d].max(v[12+d]) - v[d].min(v[8+d]);
        original *= v[4+d] - v[d];
    }
    joined - original
}
