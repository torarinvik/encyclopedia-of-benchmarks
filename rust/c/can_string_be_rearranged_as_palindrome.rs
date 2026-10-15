/// Can lowercase ASCII letters be rearranged into a palindrome?
#[no_mangle]
pub unsafe extern "C" fn can_string_be_rearranged_as_palindrome(text: *const i64, length: usize) -> i64 {
    if length == 0 || length > 4096 { return -1; }
    let text = std::slice::from_raw_parts(text, length);
    let mut counts = [0_usize; 26];
    let mut odd_count = 0_usize;
    for &value in text {
        if !(97..=122).contains(&value) { return -1; }
        let letter = (value - 97) as usize;
        if counts[letter] & 1 == 0 { odd_count += 1; }
        else { odd_count -= 1; }
        counts[letter] += 1;
    }
    i64::from(odd_count <= 1)
}
