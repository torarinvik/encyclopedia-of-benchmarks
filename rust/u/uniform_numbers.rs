/// Count positive repdigits up to the input using the pinned prefix formula.
#[no_mangle]
pub extern "C" fn uniform_numbers(value: i64) -> i64 {
    if !(0..=999_999_999).contains(&value) { return -1; }
    let mut remaining = value;
    let mut first_digit = 0;
    let mut digits = 0;
    loop {
        first_digit = remaining % 10;
        remaining /= 10;
        digits += 1;
        if remaining == 0 { break; }
    }
    let mut repeated = 0;
    for _ in 0..digits { repeated = repeated * 10 + first_digit; }
    let count = (digits - 1) * 9;
    count + if repeated <= value { first_digit } else { first_digit - 1 }
}
