const MAX_INPUT_LENGTH: usize = 255;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 256;
const MAX_TOKEN_COUNT: usize = 63;
const MAX_OPERAND_MAGNITUDE: i64 = 1_000_000;
const MAX_INTERMEDIATE_MAGNITUDE: f64 = 1.0e200;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn reverse_polish_notation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    if length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|&value| !(0..=127).contains(&value)) {
        return INVALID_RESULT;
    }

    let mut stack = [0.0_f64; MAX_TOKEN_COUNT];
    let mut top = 0;
    let mut position = 0;
    let mut token_count = 0;
    while position < length {
        let token_start = position;
        while position < length && input[position] != 32 {
            position += 1;
        }
        let token_length = position - token_start;
        if token_length == 0 {
            return INVALID_RESULT;
        }
        token_count += 1;
        if token_count > MAX_TOKEN_COUNT {
            return INVALID_RESULT;
        }

        let token = input[token_start];
        let is_operator = token_length == 1 &&
            (token == 43 || token == 45 || token == 42 || token == 47);
        if is_operator {
            if top < 2 {
                return INVALID_RESULT;
            }
            let a = stack[top - 1];
            let b = stack[top - 2];
            let result = if token == 43 {
                a + b
            } else if token == 45 {
                a - b
            } else if token == 42 {
                a * b
            } else {
                if a == 0.0 {
                    return INVALID_RESULT;
                }
                b / a
            };
            if !result.is_finite() || result < -MAX_INTERMEDIATE_MAGNITUDE ||
                result > MAX_INTERMEDIATE_MAGNITUDE {
                return INVALID_RESULT;
            }
            stack[top - 2] = result;
            top -= 1;
        } else {
            let mut number_position = token_start;
            let mut negative = false;
            if input[number_position] == 43 || input[number_position] == 45 {
                negative = input[number_position] == 45;
                number_position += 1;
            }
            if number_position == position {
                return INVALID_RESULT;
            }

            let mut magnitude = 0_i64;
            while number_position < position {
                let byte = input[number_position];
                number_position += 1;
                if byte < 48 || byte > 57 {
                    return INVALID_RESULT;
                }
                let digit = byte - 48;
                if magnitude > (MAX_OPERAND_MAGNITUDE - digit) / 10 {
                    return INVALID_RESULT;
                }
                magnitude = magnitude * 10 + digit;
            }
            if top >= MAX_TOKEN_COUNT {
                return INVALID_RESULT;
            }
            let mut value = magnitude as f64;
            if negative {
                value = -value;
            }
            stack[top] = value;
            top += 1;
        }

        if position < length {
            position += 1;
            if position == length || input[position] == 32 {
                return INVALID_RESULT;
            }
        }
    }
    if token_count == 0 || top != 1 {
        return INVALID_RESULT;
    }
    let result = stack[0];
    if !result.is_finite() || result < -MAX_INTERMEDIATE_MAGNITUDE ||
        result > MAX_INTERMEDIATE_MAGNITUDE {
        return INVALID_RESULT;
    }
    result
}
