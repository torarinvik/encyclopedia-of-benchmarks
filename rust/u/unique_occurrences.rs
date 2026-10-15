/// Check whether every present value has a distinct occurrence count.
#[no_mangle]
pub extern "C" fn unique_occurrences(values: *const i64, length: usize) -> i64 {
    if length > 1000 {
        return -1;
    }
    if length == 0 {
        return 1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut counts = [0i64; 2001];
    let mut seen_frequencies = [false; 1001];
    for &value in values {
        if !(-1000..=1000).contains(&value) {
            return -1;
        }
        counts[(value + 1000) as usize] += 1;
    }
    for frequency in counts {
        if frequency == 0 {
            continue;
        }
        if seen_frequencies[frequency as usize] {
            return 0;
        }
        seen_frequencies[frequency as usize] = true;
    }
    1
}
