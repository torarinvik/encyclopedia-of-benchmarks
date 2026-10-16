const MAX_BINARY_DIGIT_NUMERAL: i64 = 1_111_111_111_111_111;

#[no_mangle]
pub extern "C" fn twos_complement_of_binary(value: i64) -> i64 {
    if value < 0 || value > MAX_BINARY_DIGIT_NUMERAL { return -1; }
    if value == 0 { return 0; }

    let mut remaining = value;
    while remaining > 0 {
        let digit = remaining % 10;
        if digit != 0 && digit != 1 { return -1; }
        remaining /= 10;
    }

    remaining = value;
    let mut reversed = 0i64;
    let mut width = 0i64;
    while remaining > 0 && remaining % 10 == 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        width += 1;
    }
    if remaining > 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        width += 1;
    }
    while remaining > 0 {
        let digit = remaining % 10;
        reversed = reversed * 10 + if digit == 1 { 0 } else { 1 };
        remaining /= 10;
        width += 1;
    }

    let mut result = 0i64;
    while width > 0 {
        result = result * 10 + reversed % 10;
        reversed /= 10;
        width -= 1;
    }
    result
}
