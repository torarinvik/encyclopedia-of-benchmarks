/// Compare lowercase ASCII alphanumeric strings in natural order.
fn is_digit(value: i64) -> bool { (48..=57).contains(&value) }
fn valid_string(values: &[i64]) -> bool {
    for i in 0..values.len() {
        if !is_digit(values[i]) && !(97..=122).contains(&values[i]) { return false; }
        if values[i] == 48 && i > 0 && is_digit(values[i - 1]) { return false; }
    }
    true
}
#[no_mangle]
pub extern "C" fn alpha_numerical_sort(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=64).contains(&values[0]) { return -2; }
    let first_length = values[0] as usize;
    if 1 + first_length >= length || !(0..=64).contains(&values[1 + first_length]) { return -2; }
    let second_length = values[1 + first_length] as usize;
    if length != 2 + first_length + second_length { return -2; }
    let first = &values[2..2 + first_length];
    let second = &values[2 + first_length..];
    if !valid_string(first) || !valid_string(second) { return -2; }
    let (mut i, mut j) = (0, 0);
    while i < first_length && j < second_length {
        let (a, b) = (first[i], second[j]);
        if is_digit(a) && is_digit(b) {
            let (mut end_a, mut end_b) = (i, j);
            while end_a < first_length && is_digit(first[end_a]) { end_a += 1; }
            while end_b < second_length && is_digit(second[end_b]) { end_b += 1; }
            let (digits_a, digits_b) = (end_a - i, end_b - j);
            if digits_a != digits_b { return if digits_a < digits_b { -1 } else { 1 }; }
            for k in 0..digits_a {
                if first[i + k] != second[j + k] { return if first[i + k] < second[j + k] { -1 } else { 1 }; }
            }
            i = end_a; j = end_b;
        } else {
            if a != b { return if a < b { -1 } else { 1 }; }
            i += 1; j += 1;
        }
    }
    if i == first_length && j == second_length { 0 }
    else if i == first_length { -1 } else { 1 }
}
