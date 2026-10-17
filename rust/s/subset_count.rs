use std::slice;

const MAX_INPUT_LENGTH: usize = 33;

#[no_mangle]
pub unsafe extern "C" fn subset_count(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = slice::from_raw_parts(values, length);
    let count_value = values[0];
    let target_value = values[1];
    if !(1..=30).contains(&count_value) || !(0..=64).contains(&target_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 2 || values[2..].iter().any(|&value| !(0..=64).contains(&value)) {
        return -1;
    }

    let target = target_value as usize;
    let mut previous = [0i64; 65];
    previous[0] = 1;
    let first_value = values[2] as usize;
    if first_value <= target {
        previous[first_value] = 1;
    }

    for &value in &values[3..] {
        let value = value as usize;
        let mut current = [0i64; 65];
        current[0] = 1;
        for amount in 1..=target {
            let not_taken = previous[amount];
            let taken = if value <= amount { previous[amount - value] } else { 0 };
            current[amount] = not_taken + taken;
        }
        previous = current;
    }
    previous[target]
}
