/// Check lowercase strings for equal letter sets and frequency multisets.
#[no_mangle]
pub extern "C" fn close_strings(input: *const i64, length: usize) -> i64 {
    if !(2..=514).contains(&length) || input.is_null() {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let first_length_value = input[0];
    let second_length_value = input[1];
    if !(0..=256).contains(&first_length_value) || !(0..=256).contains(&second_length_value) {
        return -1;
    }
    let first_length = first_length_value as usize;
    let second_length = second_length_value as usize;
    if length != 2 + first_length + second_length {
        return -1;
    }
    let mut first = [0i64; 26];
    let mut second = [0i64; 26];
    for &value in &input[2..2 + first_length] {
        if !(97..=122).contains(&value) {
            return -1;
        }
        first[(value - 97) as usize] += 1;
    }
    for &value in &input[2 + first_length..] {
        if !(97..=122).contains(&value) {
            return -1;
        }
        second[(value - 97) as usize] += 1;
    }
    if first_length != second_length {
        return 0;
    }
    let mut first_frequencies = [0i64; 257];
    let mut second_frequencies = [0i64; 257];
    for letter in 0..26 {
        if (first[letter] == 0) != (second[letter] == 0) {
            return 0;
        }
        first_frequencies[first[letter] as usize] += 1;
        second_frequencies[second[letter] as usize] += 1;
    }
    if first_frequencies == second_frequencies { 1 } else { 0 }
}
