const MAX_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + 8 * MAX_COUNT;

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_keys_union(raw: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if raw.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(raw, length) };
    let raw_count = values[0];
    if raw_count < 1 || raw_count > MAX_COUNT as i64 || length != 1 + 8 * raw_count as usize { return -1; }
    let mut bounds = [0_i64; 8];
    for d in 0..4 { bounds[d] = values[1+d]; bounds[4+d] = values[5+d]; }
    for i in 0..raw_count as usize {
        let at = 1 + 8 * i;
        for d in 0..4 {
            let lo = values[at+d]; let hi = values[at+4+d];
            if !(-8..=8).contains(&lo) || !(-8..=8).contains(&hi) || lo > hi { return -1; }
            bounds[d] = bounds[d].min(lo); bounds[4+d] = bounds[4+d].max(hi);
        }
    }
    if output.is_null() || output_capacity < 64 { return -2; }
    for (i, value) in bounds.iter().enumerate() {
        let bytes = value.to_le_bytes();
        for b in 0..8 { unsafe { *output.add(i*8+b) = bytes[b]; } }
    }
    64
}
