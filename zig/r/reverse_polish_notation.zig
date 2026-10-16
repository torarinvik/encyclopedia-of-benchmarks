const MAX_INPUT_LENGTH: usize = 255;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 256;
const MAX_TOKEN_COUNT: usize = 63;
const MAX_OPERAND_MAGNITUDE: i64 = 1_000_000;
const MAX_INTERMEDIATE_MAGNITUDE: f64 = 1.0e200;
const INVALID_RESULT: f64 = -1.0e300;

export fn reverse_polish_notation(values: [*c]const i64, length: usize) f64 {
    if (values == null or length == 0 or length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 127) return INVALID_RESULT;
    }

    var stack: [MAX_TOKEN_COUNT]f64 = @splat(0.0);
    var top: usize = 0;
    var position: usize = 0;
    var token_count: usize = 0;
    while (position < length) {
        const token_start = position;
        while (position < length and values[position] != 32) : (position += 1) {}
        const token_length = position - token_start;
        if (token_length == 0) return INVALID_RESULT;
        token_count += 1;
        if (token_count > MAX_TOKEN_COUNT) return INVALID_RESULT;

        const token = values[token_start];
        const is_operator = token_length == 1 and
            (token == 43 or token == 45 or token == 42 or token == 47);
        if (is_operator) {
            if (top < 2) return INVALID_RESULT;
            const a = stack[top - 1];
            const b = stack[top - 2];
            var result: f64 = 0.0;
            if (token == 43) {
                result = a + b;
            } else if (token == 45) {
                result = a - b;
            } else if (token == 42) {
                result = a * b;
            } else {
                if (a == 0.0) return INVALID_RESULT;
                result = b / a;
            }
            if (result != result or result < -MAX_INTERMEDIATE_MAGNITUDE or
                result > MAX_INTERMEDIATE_MAGNITUDE) return INVALID_RESULT;
            stack[top - 2] = result;
            top -= 1;
        } else {
            var number_position = token_start;
            var negative = false;
            if (values[number_position] == 43 or values[number_position] == 45) {
                negative = values[number_position] == 45;
                number_position += 1;
            }
            if (number_position == position) return INVALID_RESULT;

            var magnitude: i64 = 0;
            while (number_position < position) : (number_position += 1) {
                const byte = values[number_position];
                if (byte < 48 or byte > 57) return INVALID_RESULT;
                const digit = byte - 48;
                if (magnitude > @divTrunc(MAX_OPERAND_MAGNITUDE - digit, 10))
                    return INVALID_RESULT;
                magnitude = magnitude * 10 + digit;
            }
            if (top >= MAX_TOKEN_COUNT) return INVALID_RESULT;
            var value: f64 = @floatFromInt(magnitude);
            if (negative) value = -value;
            stack[top] = value;
            top += 1;
        }

        if (position < length) {
            position += 1;
            if (position == length or values[position] == 32) return INVALID_RESULT;
        }
    }
    if (token_count == 0 or top != 1) return INVALID_RESULT;
    const result = stack[0];
    if (result != result or result < -MAX_INTERMEDIATE_MAGNITUDE or
        result > MAX_INTERMEDIATE_MAGNITUDE) return INVALID_RESULT;
    return result;
}
