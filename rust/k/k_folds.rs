#[no_mangle]
pub unsafe extern "C" fn k_folds(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (sample_count, fold_count) = (values[0], values[1]);
    if !(1..=12).contains(&sample_count) || !(1..=12).contains(&fold_count) { return -1; }
    let width = (sample_count + fold_count - 1) / fold_count;
    let mut packed = (sample_count as u64) << 48;
    for index in 0..sample_count {
        let fold = ((index + width) / width) as u64;
        packed |= fold << (4 * index as u32);
    }
    packed as i64
}
