/// Reverse bytes by swapping inward from both ends.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub unsafe extern "C" fn reverse_string_in_place(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(0..=255).contains(&value) { return -1; }
    }
    if output_capacity < length || (length != 0 && output.is_null()) { return -2; }
    for index in 0..length { *output.add(index) = *input.add(index) as u8; }
    let mut left = 0;
    let mut right = length;
    while left < right {
        right -= 1;
        if left >= right { break; }
        let temporary = *output.add(left);
        *output.add(left) = *output.add(right);
        *output.add(right) = temporary;
        left += 1;
    }
    length as i64
}
