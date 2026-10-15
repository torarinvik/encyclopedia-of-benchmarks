/// Reverse ASCII letters while leaving every other printable byte in place.
const MAX_LENGTH: usize = 4096;

fn is_ascii_letter(value: u8) -> bool {
    value.is_ascii_alphabetic()
}

#[no_mangle]
pub unsafe extern "C" fn reverse_only_letters(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(32..=126).contains(&value) { return -1; }
    }
    if output_capacity < length || (length != 0 && output.is_null()) { return -2; }
    for index in 0..length { *output.add(index) = *input.add(index) as u8; }

    let mut left = 0;
    let mut right = length;
    while left < right {
        if !is_ascii_letter(*output.add(left)) {
            left += 1;
        } else if !is_ascii_letter(*output.add(right - 1)) {
            right -= 1;
        } else {
            let temporary = *output.add(left);
            *output.add(left) = *output.add(right - 1);
            *output.add(right - 1) = temporary;
            left += 1;
            right -= 1;
        }
    }
    length as i64
}
