fn digit_at_position(mut position: i64) -> i64 {
    let mut digits = 1i64;
    let mut block_count = 9i64;
    let mut first_number = 1i64;
    while position > digits * block_count {
        position -= digits * block_count;
        digits += 1;
        block_count *= 10;
        first_number *= 10;
    }
    let number = first_number + (position - 1) / digits;
    let offset = (position - 1) % digits;
    let mut divisor = 1i64;
    for _ in 0..(digits - offset - 1) {
        divisor *= 10;
    }
    (number / divisor) % 10
}

#[no_mangle]
pub extern "C" fn problem40(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut product = digit_at_position(1);
    product *= digit_at_position(10);
    product *= digit_at_position(100);
    product *= digit_at_position(1_000);
    product *= digit_at_position(10_000);
    product *= digit_at_position(100_000);
    product *= digit_at_position(1_000_000);
    product
}
