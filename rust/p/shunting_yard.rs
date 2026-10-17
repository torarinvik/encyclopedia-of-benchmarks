const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_VALUES: usize = 257;
const MAX_EXPRESSION_BYTES: i64 = 255;
const MAX_OPERANDS: usize = 16;
const MAX_OPERATORS: usize = 15;
const MAX_LITERAL_BYTES: usize = 16;
const MAX_LITERAL_VALUE: f64 = 1_000_000.0;
const MAX_INTERMEDIATE: f64 = 1_000_000_000_000.0;

#[inline(never)]
fn rounded_multiply(left: f64, right: f64) -> f64 { std::hint::black_box(left * right) }

#[inline(never)]
fn rounded_add(left: f64, right: f64) -> f64 { std::hint::black_box(left + right) }

#[inline(never)]
fn rounded_divide(left: f64, right: f64) -> f64 { std::hint::black_box(left / right) }

fn precedence(operator: u8) -> u8 {
    match operator { b'^' => 3, b'*' | b'/' => 2, _ => 1 }
}

fn apply_operator(numbers: &mut [f64; MAX_OPERANDS], number_count: &mut usize,
                  operator: u8) -> bool {
    if *number_count < 2 { return false; }
    *number_count -= 1;
    let right = numbers[*number_count];
    *number_count -= 1;
    let left = numbers[*number_count];
    let result = match operator {
        b'+' => left + right,
        b'-' => left - right,
        b'*' => left * right,
        b'/' => { if right == 0.0 { return false; } left / right },
        b'^' => left.powf(right),
        _ => return false,
    };
    if !result.is_finite() || result.abs() > MAX_INTERMEDIATE { return false; }
    numbers[*number_count] = result;
    *number_count += 1;
    true
}

#[no_mangle]
pub unsafe extern "C" fn shunting_yard(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return INVALID_RESULT; }
    let byte_count_value = *input;
    if !(1..=MAX_EXPRESSION_BYTES).contains(&byte_count_value) { return INVALID_RESULT; }
    let byte_count = byte_count_value as usize;
    if length != byte_count + 1 { return INVALID_RESULT; }

    let mut numbers = [0.0; MAX_OPERANDS];
    let mut operators = [0u8; MAX_OPERATORS];
    let mut number_count = 0usize;
    let mut operator_count = 0usize;
    let mut operand_count = 0usize;
    let mut seen_operator_count = 0usize;
    let mut position = 0usize;
    let mut expect_number = true;
    while position < byte_count {
        let raw = *input.add(position + 1);
        if !(0..=127).contains(&raw) { return INVALID_RESULT; }
        let character = raw as u8;
        if character == b' ' || (b'\t'..=b'\r').contains(&character) {
            position += 1;
            continue;
        }
        if expect_number {
            let start = position;
            let mut integer_digits = 0usize;
            let mut number = 0.0;
            while position < byte_count {
                let digit = *input.add(position + 1);
                if !(48..=57).contains(&digit) { break; }
                number = rounded_add(rounded_multiply(number, 10.0), (digit - 48) as f64);
                integer_digits += 1;
                position += 1;
            }
            if integer_digits == 0 { return INVALID_RESULT; }
            if position < byte_count && *input.add(position + 1) == 46 {
                position += 1;
                let mut fraction_digits = 0usize;
                let mut scale = 0.1;
                while position < byte_count {
                    let digit = *input.add(position + 1);
                    if !(48..=57).contains(&digit) { break; }
                    let product = rounded_multiply((digit - 48) as f64, scale);
                    number = rounded_add(number, product);
                    scale = rounded_divide(scale, 10.0);
                    fraction_digits += 1;
                    position += 1;
                }
                if fraction_digits == 0 { return INVALID_RESULT; }
            }
            if position - start > MAX_LITERAL_BYTES || number > MAX_LITERAL_VALUE || operand_count >= MAX_OPERANDS {
                return INVALID_RESULT;
            }
            numbers[number_count] = number;
            number_count += 1;
            operand_count += 1;
            expect_number = false;
        } else {
            if !matches!(character, b'+' | b'-' | b'*' | b'/' | b'^') { return INVALID_RESULT; }
            while operator_count > 0 {
                let top = operators[operator_count - 1];
                let top_precedence = precedence(top);
                let current_precedence = precedence(character);
                if top_precedence < current_precedence ||
                    (top_precedence == current_precedence && character == b'^') { break; }
                operator_count -= 1;
                if !apply_operator(&mut numbers, &mut number_count, top) { return INVALID_RESULT; }
            }
            if operator_count >= MAX_OPERATORS { return INVALID_RESULT; }
            operators[operator_count] = character;
            operator_count += 1;
            seen_operator_count += 1;
            position += 1;
            expect_number = true;
        }
    }
    if expect_number || operand_count == 0 || seen_operator_count + 1 != operand_count {
        return INVALID_RESULT;
    }
    while operator_count > 0 {
        operator_count -= 1;
        if !apply_operator(&mut numbers, &mut number_count, operators[operator_count]) {
            return INVALID_RESULT;
        }
    }
    if number_count != 1 { return INVALID_RESULT; }
    numbers[0]
}
