fn get_check_digit(input: i64) -> i64 {
    let mut barcode = input / 10;
    let mut checker = false;
    let mut total = 0_i64;
    while barcode != 0 {
        let multiplier = if checker { 1_i64 } else { 3_i64 };
        total += multiplier * (barcode % 10);
        barcode /= 10;
        checker = !checker;
    }
    (10 - total % 10) % 10
}

fn decimal_length(mut value: i64) -> usize {
    let mut length = 1;
    while value >= 10 {
        value /= 10;
        length += 1;
    }
    length
}

#[no_mangle]
pub unsafe extern "C" fn barcode_validator(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let operation = *values;
    let barcode = *values.add(1);
    if !(0..=1).contains(&operation) || barcode < 0 { return -1; }
    if operation == 0 { return get_check_digit(barcode); }
    if decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10 { 1 } else { 0 }
}
