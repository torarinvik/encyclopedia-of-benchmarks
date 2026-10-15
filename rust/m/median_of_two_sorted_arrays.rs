/// Merge two ascending i32 arrays and return twice their exact median.
const MAX_TOTAL_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn median_of_two_sorted_arrays(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_TOTAL_LENGTH + 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_TOTAL_LENGTH as i64 ||
        values[1] < 0 || values[1] > MAX_TOTAL_LENGTH as i64 { return -1; }
    let first_count = values[0] as usize;
    let second_count = values[1] as usize;
    let total_count = first_count + second_count;
    if total_count == 0 || total_count > MAX_TOTAL_LENGTH || length != total_count + 2 { return -1; }
    let second_start = first_count + 2;
    let first = &values[2..second_start];
    let second = &values[second_start..];
    for (index, &value) in first.iter().enumerate() {
        if value < i32::MIN as i64 || value > i32::MAX as i64 ||
            (index != 0 && first[index - 1] > value) { return -1; }
    }
    for (index, &value) in second.iter().enumerate() {
        if value < i32::MIN as i64 || value > i32::MAX as i64 ||
            (index != 0 && second[index - 1] > value) { return -1; }
    }

    let mut merged = [0i32; MAX_TOTAL_LENGTH];
    let mut first_index = 0;
    let mut second_index = 0;
    let mut written = 0;
    while first_index < first_count && second_index < second_count {
        if first[first_index] <= second[second_index] {
            merged[written] = first[first_index] as i32;
            first_index += 1;
        } else {
            merged[written] = second[second_index] as i32;
            second_index += 1;
        }
        written += 1;
    }
    while first_index < first_count {
        merged[written] = first[first_index] as i32;
        first_index += 1;
        written += 1;
    }
    while second_index < second_count {
        merged[written] = second[second_index] as i32;
        second_index += 1;
        written += 1;
    }
    if total_count % 2 != 0 { return i64::from(merged[total_count / 2]) * 2; }
    i64::from(merged[total_count / 2 - 1]) + i64::from(merged[total_count / 2])
}
