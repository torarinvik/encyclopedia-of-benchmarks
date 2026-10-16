/// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
#[no_mangle]
pub unsafe extern "C" fn string_prefix_suffix(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 2052 { return -1; }
    let mode = *values;
    let text_count_value = *values.add(1);
    let pattern_count_value = *values.add(2);
    if (mode != 0 && mode != 1) || !(0..=1024).contains(&text_count_value)
        || !(0..=1024).contains(&pattern_count_value) { return -1; }
    let text_count = text_count_value as usize;
    let pattern_count = pattern_count_value as usize;
    if length != 3 + text_count + pattern_count { return -1; }
    for index in 0..text_count + pattern_count {
        let unit = *values.add(3 + index);
        if !(0..=65535).contains(&unit) { return -1; }
    }
    if pattern_count > text_count { return 0; }
    let start = if mode == 0 { 0 } else { text_count - pattern_count };
    for index in 0..pattern_count {
        if *values.add(3 + start + index) != *values.add(3 + text_count + index) { return 0; }
    }
    1
}
