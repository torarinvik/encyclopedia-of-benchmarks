/// Count chunks by greedily peeling the shortest matching prefix and suffix.
#[no_mangle]
pub extern "C" fn longest_chunked_palindrome_decomposition(text: *const i64, length: usize) -> i64 {
    if length > 128 { return -1; }
    let text = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(text, length) } };
    if text.iter().any(|&value| !(1..=127).contains(&value)) { return -1; }
    let (mut left, mut right) = (0usize, length);
    let mut chunks = 0i64;
    while left < right {
        let remaining = right - left;
        let mut matched = false;
        for size in 1..=remaining / 2 {
            if text[left..left + size] == text[right - size..right] {
                chunks += 2;
                left += size;
                right -= size;
                matched = true;
                break;
            }
        }
        if !matched { return chunks + 1; }
    }
    chunks
}
