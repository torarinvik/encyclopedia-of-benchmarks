const MIN_NUMBER: i64 = 10_100_000;
const MAX_NUMBER: i64 = 99_923_199_999;
const WEIGHTS: [i64; 4] = [1, 3, 7, 9];

#[no_mangle]
pub unsafe extern "C" fn is_polish_national_id(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 11 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|value| *value < 48 || *value > 57) { return -1; }
    let mut number = 0i64;
    for value in values { number = number * 10 + *value - 48; }
    if number < MIN_NUMBER || number > MAX_NUMBER { return 0; }
    let month = (values[2] - 48) * 10 + values[3] - 48;
    let valid_month = (1..=12).contains(&month) || (21..=32).contains(&month) ||
        (41..=52).contains(&month) || (61..=72).contains(&month) || (81..=92).contains(&month);
    if !valid_month { return 0; }
    let day = (values[4] - 48) * 10 + values[5] - 48;
    if !(1..=31).contains(&day) { return 0; }
    let mut subtotal = 0i64;
    for index in 0..10 { subtotal += ((values[index] - 48) * WEIGHTS[index % 4]) % 10; }
    let checksum = 10 - subtotal % 10;
    if checksum == number % 10 { 1 } else { 0 }
}
