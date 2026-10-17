const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const MAX_DIGITS: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn large_number_add(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let (left_length_value, right_length_value) = unsafe { (*input, *input.add(1)) };
    if !(1..=MAX_DIGITS as i64).contains(&left_length_value) ||
        !(1..=MAX_DIGITS as i64).contains(&right_length_value) { return -1; }
    let left_length = left_length_value as usize;
    let right_length = right_length_value as usize;
    if input_length != 2 + left_length + right_length { return -1; }

    let mut left = [0_u8; MAX_DIGITS];
    let mut right = [0_u8; MAX_DIGITS];
    for index in 0..left_length {
        let digit = unsafe { *input.add(2 + index) };
        if !(48..=57).contains(&digit) || (index == 0 && left_length > 1 && digit == 48) { return -1; }
        left[left_length - index - 1] = (digit - 48) as u8;
    }
    for index in 0..right_length {
        let digit = unsafe { *input.add(2 + left_length + index) };
        if !(48..=57).contains(&digit) || (index == 0 && right_length > 1 && digit == 48) { return -1; }
        right[right_length - index - 1] = (digit - 48) as u8;
    }

    let mut sum = [0_u8; MAX_DIGITS + 1];
    let mut sum_length = 0usize;
    let mut carry = 0_u8;
    while sum_length < left_length.max(right_length) || carry != 0 {
        let mut total = carry;
        if sum_length < right_length { total += right[sum_length]; }
        if sum_length < left_length { total += left[sum_length]; }
        sum[sum_length] = total % 10;
        carry = total / 10;
        sum_length += 1;
    }
    let mut staged = [0_u8; MAX_DIGITS + 1];
    for index in 0..sum_length { staged[index] = b'0' + sum[sum_length - index - 1]; }
    if output.is_null() || output_capacity < sum_length { return -2; }
    for index in 0..sum_length { unsafe { *output.add(index) = staged[index]; } }
    sum_length as i64
}
