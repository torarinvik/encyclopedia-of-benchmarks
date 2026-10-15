/// Sum an inclusive arithmetic progression from packed [from, to, step].
#[no_mangle]
pub unsafe extern "C" fn arithmetic_progression(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (from, to, step) = (values[0], values[1], values[2]);
    if !(-1_000_000..=1_000_000).contains(&from)
        || !(-1_000_000..=1_000_000).contains(&to)
        || !(-1_000_000..=1_000_000).contains(&step)
        || step == 0
    { return -1; }
    if (from < to && step < 0) || (from > to && step > 0) { return -1; }
    let count = (to - from) / step;
    let last = from + count * step;
    ((count + 1) * (from + last)) / 2
}
