/// Return the earliest split with the smallest difference of integer averages.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

#[no_mangle]
pub extern "C" fn minimum_average_difference(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(0..=MAX_VALUE).contains(&value)) { return -1; }
    let total_sum: i64 = input.iter().sum();
    let mut prefix_sum = 0i64;
    let mut best_difference = i64::MAX;
    let mut best_index = 0usize;
    for (index, &value) in input.iter().enumerate() {
        prefix_sum += value;
        let left_average = prefix_sum / (index as i64 + 1);
        let suffix_length = length - index - 1;
        let right_average = if suffix_length == 0 { 0 }
            else { (total_sum - prefix_sum) / suffix_length as i64 };
        let difference = (left_average - right_average).abs();
        if difference < best_difference {
            best_difference = difference;
            best_index = index;
        }
    }
    best_index as i64
}
