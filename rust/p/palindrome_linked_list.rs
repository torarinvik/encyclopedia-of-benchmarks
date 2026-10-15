/// Compare the linked-list value sequence from both ends without mutation.
#[no_mangle]
pub extern "C" fn palindrome_linked_list(values: *const i64, length: usize) -> i64 {
    if length > 100000 { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(0..=9).contains(&value)) { return -1; }

    let (mut left, mut right) = (0usize, length);
    while left < right {
        right -= 1;
        if values[left] != values[right] { return 0; }
        left += 1;
    }
    1
}
