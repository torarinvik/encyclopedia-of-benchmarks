/// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
const MAX_LENGTH: usize = 4096;

fn count_for_target(values: &[i64], target: i64) -> i64 {
    let mut first_count = 0i64;
    let mut middle_count = 0i64;
    let mut ways = 0i64;
    for &value in values {
        if value == target {
            ways += middle_count;
            first_count += 1;
        } else {
            middle_count += first_count;
        }
    }
    ways
}

#[no_mangle]
pub extern "C" fn number_of_ways_to_select_buildings(values: *const i64, length: usize) -> i64 {
    if length == 0 { return 0; }
    if values.is_null() || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value != 48 && value != 49) { return -1; }
    count_for_target(input, 48) + count_for_target(input, 49)
}
