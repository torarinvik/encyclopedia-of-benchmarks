#[derive(Clone, Copy)]
struct Operand {
    start: usize,
    digits: usize,
    negative: bool,
}

fn parse_operand(values: &[i64], start: usize, text_length: usize) -> Option<Operand> {
    if text_length == 0 || text_length > 33 {
        return None;
    }
    let negative = values[start] == 45;
    let sign_length = if negative { 1 } else { 0 };
    let digit_start = start + sign_length;
    let digit_count = text_length - sign_length;
    if digit_count == 0 || digit_count > 32 {
        return None;
    }
    for index in 0..digit_count {
        let byte = values[digit_start + index];
        if !(48..=57).contains(&byte) || (index == 0 && digit_count > 1 && byte == 48) {
            return None;
        }
    }
    if negative && digit_count == 1 && values[digit_start] == 48 {
        return None;
    }
    Some(Operand { start: digit_start, digits: digit_count, negative })
}

fn compare_magnitude(values: &[i64], a: Operand, b: Operand) -> i32 {
    if a.digits != b.digits {
        return if a.digits > b.digits { 1 } else { -1 };
    }
    for index in 0..a.digits {
        let da = values[a.start + index];
        let db = values[b.start + index];
        if da != db {
            return if da > db { 1 } else { -1 };
        }
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn addition_of_big_integers(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=68).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let raw_a = values[0];
    let raw_b = values[1];
    if !(1..=33).contains(&raw_a) || !(1..=33).contains(&raw_b) {
        return -1;
    }
    let len_a = raw_a as usize;
    let len_b = raw_b as usize;
    if length != 2 + len_a + len_b {
        return -1;
    }
    let Some(a) = parse_operand(values, 2, len_a) else { return -1 };
    let Some(b) = parse_operand(values, 2 + len_a, len_b) else { return -1 };

    let mut reversed = [0u8; 33];
    let mut digits = 0usize;
    let mut negative = false;
    if a.negative == b.negative {
        negative = a.negative;
        let width = a.digits.max(b.digits);
        let mut carry = 0i64;
        for offset in 0..width {
            let da = if offset < a.digits { values[a.start + a.digits - 1 - offset] - 48 } else { 0 };
            let db = if offset < b.digits { values[b.start + b.digits - 1 - offset] - 48 } else { 0 };
            let total = da + db + carry;
            reversed[digits] = (total % 10) as u8;
            digits += 1;
            carry = total / 10;
        }
        if carry != 0 {
            reversed[digits] = carry as u8;
            digits += 1;
        }
    } else {
        let order = compare_magnitude(values, a, b);
        if order == 0 {
            reversed[0] = 0;
            digits = 1;
        } else {
            let (larger, smaller) = if order > 0 { (a, b) } else { (b, a) };
            negative = larger.negative;
            let mut borrow = 0i64;
            for offset in 0..larger.digits {
                let da = values[larger.start + larger.digits - 1 - offset] - 48;
                let db = if offset < smaller.digits {
                    values[smaller.start + smaller.digits - 1 - offset] - 48
                } else { 0 };
                let digit = da - db - borrow;
                borrow = if digit < 0 { 1 } else { 0 };
                reversed[digits] = (if digit < 0 { digit + 10 } else { digit }) as u8;
                digits += 1;
            }
            while digits > 1 && reversed[digits - 1] == 0 {
                digits -= 1;
            }
        }
    }

    let output_length = digits + (if negative { 1 } else { 0 });
    if output.is_null() || capacity < output_length {
        return -2;
    }
    let mut cursor = 0usize;
    if negative {
        *output.add(cursor) = 45;
        cursor += 1;
    }
    for index in 0..digits {
        *output.add(cursor) = 48 + reversed[digits - 1 - index];
        cursor += 1;
    }
    output_length as i64
}
