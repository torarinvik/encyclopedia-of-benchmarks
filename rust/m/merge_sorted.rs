const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_ARRAY_LENGTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

#[no_mangle]
pub unsafe extern "C" fn merge_sorted(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_ARRAY_LENGTH as i64 ||
        input[1] < 0 || input[1] > MAX_ARRAY_LENGTH as i64 {
        return -1;
    }

    let left_count = input[0] as usize;
    let right_count = input[1] as usize;
    if length != 2 + left_count + right_count {
        return -1;
    }
    let right_start = 2 + left_count;
    for index in 0..left_count {
        let value = input[2 + index];
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) ||
            (index > 0 && input[2 + index - 1] > value) {
            return -1;
        }
    }
    for index in 0..right_count {
        let value = input[right_start + index];
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) ||
            (index > 0 && input[right_start + index - 1] > value) {
            return -1;
        }
    }

    let mut left_index = 0;
    let mut right_index = 0;
    let mut output_index = 0_i64;
    let mut checksum = 0_i64;
    while left_index < left_count && right_index < right_count {
        let value = if input[2 + left_index] <= input[right_start + right_index] {
            let value = input[2 + left_index];
            left_index += 1;
            value
        } else {
            let value = input[right_start + right_index];
            right_index += 1;
            value
        };
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        output_index += 1;
    }
    while left_index < left_count {
        let value = input[2 + left_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        left_index += 1;
        output_index += 1;
    }
    while right_index < right_count {
        let value = input[right_start + right_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        right_index += 1;
        output_index += 1;
    }
    checksum
}
