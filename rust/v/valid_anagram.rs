/// Compare lowercase ASCII strings by their letter frequencies.
#[no_mangle]
pub extern "C" fn valid_anagram(input: *const i64, length: usize) -> i64 {
    if !(2..=2050).contains(&length) || input.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (first, second) = (values[0] as u64, values[1] as u64);
    if first > 1024 || second > 1024 || length as u64 != 2 + first + second { return -1; }
    let letters = &values[2..];
    if first != second {
        return if letters.iter().any(|&value| (value as u64).wrapping_sub(97) > 25) { -1 } else { 0 };
    }

    let mut counts = [0u16; 26];
    let (first, second) = letters.split_at(first as usize);
    for (&left, &right) in first.iter().zip(second) {
        let left = (left as u64).wrapping_sub(97);
        let right = (right as u64).wrapping_sub(97);
        if left > 25 || right > 25 { return -1; }
        if left != right {
            let (left, right) = (left as usize, right as usize);
            counts[left] = counts[left].wrapping_add(1);
            counts[right] = counts[right].wrapping_sub(1);
        }
    }
    i64::from(counts.iter().all(|&balance| balance == 0))
}
