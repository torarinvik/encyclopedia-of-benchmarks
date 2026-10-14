const MAX_VALUES: usize = 256;
const MAX_INPUT_VALUES: usize = MAX_VALUES + 1;
const VALUE_LIMIT: i64 = 1_000_000_000;

fn magnitude(value: i64) -> i64 { if value < 0 { -value } else { value } }

unsafe fn select_absolute(values: *const i64, length: usize, maximum: bool) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let count_value = *values;
    if !(1..=MAX_VALUES as i64).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    for index in 1..length {
        let value = *values.add(index);
        if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value) { return -1; }
    }
    let mut best = *values.add(1);
    for index in 2..length {
        let candidate = *values.add(index);
        if if maximum {
            magnitude(candidate) > magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate > best)
        } else {
            magnitude(candidate) < magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate < best)
        } {
            best = candidate;
        }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn absolute_max_benchmark(values: *const i64, length: usize) -> i64 {
    select_absolute(values, length, true)
}
