/// Return the lowercase byte added to t by subtracting the two character sums.
const MAX_STRING_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 8195;

#[no_mangle]
pub extern "C" fn find_the_difference(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PACKED_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_STRING_LENGTH as i64 ||
        values[1] < 1 || values[1] > (MAX_STRING_LENGTH + 1) as i64 { return -1; }
    let s_length = values[0] as usize;
    let t_length = values[1] as usize;
    if t_length != s_length + 1 || length != 2 + s_length + t_length { return -1; }
    let mut sum_s = 0_i64;
    let mut sum_t = 0_i64;
    for &value in &values[2..2 + s_length] {
        if !(97..=122).contains(&value) { return -1; }
        sum_s += value;
    }
    for &value in &values[2 + s_length..] {
        if !(97..=122).contains(&value) { return -1; }
        sum_t += value;
    }
    let difference = sum_t - sum_s;
    if !(97..=122).contains(&difference) { return -1; }
    difference
}
