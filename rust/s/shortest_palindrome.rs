/// Add the minimum prefix needed to make a printable ASCII string a palindrome.
const MAX_INPUT_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn shortest_palindrome(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_INPUT_LENGTH { return -1; }
    if length == 0 { return 0; }
    if input.is_null() { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input.iter().any(|&value| !(32..=126).contains(&value)) { return -1; }

    let mut suffix = [0usize; 64];
    for i in 1..length {
        let mut matched = suffix[i - 1];
        while matched > 0 && input[matched] != input[i] { matched = suffix[matched - 1]; }
        if input[matched] == input[i] { matched += 1; }
        suffix[i] = matched;
    }

    let mut prefix_match = 0usize;
    for i in 0..length {
        let reversed_value = input[length - 1 - i];
        while prefix_match > 0 && reversed_value != input[prefix_match] {
            prefix_match = suffix[prefix_match - 1];
        }
        if reversed_value == input[prefix_match] { prefix_match += 1; }
    }

    let output_length = 2 * length - prefix_match;
    if output.is_null() || output_capacity < output_length { return -2; }
    for i in 0..length {
        unsafe { *output.add(i) = input[length - 1 - i] as u8; }
    }
    for i in prefix_match..length {
        unsafe { *output.add(length + i - prefix_match) = input[i] as u8; }
    }
    output_length as i64
}
