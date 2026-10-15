fn kaprekar_step(number: i64) -> i64 {
    let mut d0 = number / 1000;
    let mut d1 = (number / 100) % 10;
    let mut d2 = (number / 10) % 10;
    let mut d3 = number % 10;
    let mut temp: i64 = 0;

    if d0 > d1 { temp = d0; d0 = d1; d1 = temp; }
    if d2 > d3 { temp = d2; d2 = d3; d3 = temp; }
    if d0 > d2 { temp = d0; d0 = d2; d2 = temp; }
    if d1 > d3 { temp = d1; d1 = d3; d3 = temp; }
    if d1 > d2 { temp = d1; d1 = d2; d2 = temp; }

    let ascending = d0 * 1000 + d1 * 100 + d2 * 10 + d3;
    let descending = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
    descending - ascending
}

#[no_mangle]
pub unsafe extern "C" fn kaprekar_constant(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let number = input[0];
    let max_iterations = input[1];
    if number < 0 || number > 9999 || max_iterations < 1 || max_iterations > 16 { return -1; }
    if number == 6174 { return 0; }

    let mut current = number;
    for iteration in 1..=max_iterations {
        current = kaprekar_step(current);
        if current == 6174 { return iteration; }
        if current == 0 { return -1; }
    }
    -1
}
