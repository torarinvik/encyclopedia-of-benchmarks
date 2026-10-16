module reverse_polish_notation;

const usz MAX_INPUT_LENGTH = 255;
const usz MAX_PARSEABLE_INPUT_LENGTH = 256;
const usz MAX_TOKEN_COUNT = 63;
const long MAX_OPERAND_MAGNITUDE = 1000000;
const double MAX_INTERMEDIATE_MAGNITUDE = 1.0e200;
const double INVALID_RESULT = -1.0e300;

fn double reverse_polish_notation(long* values, usz length)
    @export("reverse_polish_notation") {
    if (values == null || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (usz index = 0; index < length; index++)
        if (values[index] < 0 || values[index] > 127) return INVALID_RESULT;

    double[MAX_TOKEN_COUNT] stack = zeroed;
    top: mutable usz = 0;
    position: mutable usz = 0;
    token_count: mutable usz = 0;
    while (position < length) {
        token_start: usz = position;
        while (position < length && values[position] != 32) position++;
        token_length: usz = position - token_start;
        if (token_length == 0) return INVALID_RESULT;
        token_count++;
        if (token_count > MAX_TOKEN_COUNT) return INVALID_RESULT;

        token: long = values[token_start];
        is_operator: bool = token_length == 1 &&
            (token == 43 || token == 45 || token == 42 || token == 47);
        if (is_operator) {
            if (top < 2) return INVALID_RESULT;
            a: double = stack[top - 1];
            b: double = stack[top - 2];
            result: mutable double = 0.0;
            if (token == 43) result = a + b;
            else if (token == 45) result = a - b;
            else if (token == 42) result = a * b;
            else {
                if (a == 0.0) return INVALID_RESULT;
                result = b / a;
            }
            if (result != result || result < -MAX_INTERMEDIATE_MAGNITUDE ||
                result > MAX_INTERMEDIATE_MAGNITUDE) return INVALID_RESULT;
            stack[top - 2] = result;
            top--;
        } else {
            number_position: mutable usz = token_start;
            negative: mutable bool = false;
            if (values[number_position] == 43 || values[number_position] == 45) {
                negative = values[number_position] == 45;
                number_position++;
            }
            if (number_position == position) return INVALID_RESULT;

            magnitude: mutable long = 0;
            while (number_position < position) {
                byte: long = values[number_position];
                number_position++;
                if (byte < 48 || byte > 57) return INVALID_RESULT;
                digit: long = byte - 48;
                if (magnitude > (MAX_OPERAND_MAGNITUDE - digit) / 10)
                    return INVALID_RESULT;
                magnitude = magnitude * 10 + digit;
            }
            if (top >= MAX_TOKEN_COUNT) return INVALID_RESULT;
            value: double = (double)magnitude;
            if (negative) value = -value;
            stack[top] = value;
            top++;
        }

        if (position < length) {
            position++;
            if (position == length || values[position] == 32) return INVALID_RESULT;
        }
    }
    if (token_count == 0 || top != 1) return INVALID_RESULT;
    result: double = stack[0];
    if (result != result || result < -MAX_INTERMEDIATE_MAGNITUDE ||
        result > MAX_INTERMEDIATE_MAGNITUDE) return INVALID_RESULT;
    return result;
}
