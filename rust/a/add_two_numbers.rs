/// Add reverse-order decimal digit lists with a carry propagated per node.
const MAX_DIGITS: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn add_two_numbers(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_DIGITS { return -1; }
    let first_value = *input;
    let second_value = *input.add(1);
    if first_value < 0 || first_value > MAX_DIGITS as i64 ||
        second_value < 0 || second_value > MAX_DIGITS as i64 { return -1; }
    let first_length = first_value as usize;
    let second_length = second_value as usize;
    if length != first_length + second_length + 2 { return -1; }
    for index in 0..first_length + second_length {
        let digit = *input.add(index + 2);
        if !(0..=9).contains(&digit) { return -1; }
    }
    let digit_count = first_length.max(second_length);
    let mut digits = [0u8; MAX_DIGITS + 1];
    let mut result_length = 0;
    let mut carry = 0i64;
    let mut index = 0;
    while index < digit_count || carry != 0 {
        let first = if index < first_length { *input.add(index + 2) } else { 0 };
        let second = if index < second_length { *input.add(index + 2 + first_length) } else { 0 };
        let sum = first + second + carry;
        digits[result_length] = (sum % 10) as u8;
        result_length += 1;
        carry = sum / 10;
        index += 1;
    }
    if output_capacity < result_length || (result_length != 0 && output.is_null()) { return -2; }
    for position in 0..result_length { *output.add(position) = digits[position]; }
    result_length as i64
}
