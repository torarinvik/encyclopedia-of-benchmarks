#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 255
#define MAX_PARSEABLE_INPUT_LENGTH 256
#define MAX_TOKEN_COUNT 63
#define MAX_OPERAND_MAGNITUDE INT64_C(1000000)
#define MAX_INTERMEDIATE_MAGNITUDE 1.0e200
#define INVALID_RESULT (-1.0e300)

double reverse_polish_notation(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return INVALID_RESULT;

    double stack[MAX_TOKEN_COUNT] = {0.0};
    size_t top = 0, position = 0, token_count = 0;
    while (position < length) {
        const size_t token_start = position;
        while (position < length && values[position] != 32) ++position;
        const size_t token_length = position - token_start;
        if (token_length == 0 || ++token_count > MAX_TOKEN_COUNT)
            return INVALID_RESULT;

        const int64_t token = values[token_start];
        const int is_operator = token_length == 1 &&
            (token == 43 || token == 45 || token == 42 || token == 47);
        if (is_operator) {
            if (top < 2) return INVALID_RESULT;
            const double a = stack[top - 1];
            const double b = stack[top - 2];
            double result;
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
            --top;
        } else {
            size_t number_position = token_start;
            int negative = 0;
            if (values[number_position] == 43 || values[number_position] == 45) {
                negative = values[number_position] == 45;
                ++number_position;
            }
            if (number_position == position) return INVALID_RESULT;

            int64_t magnitude = 0;
            while (number_position < position) {
                const int64_t byte = values[number_position++];
                if (byte < 48 || byte > 57) return INVALID_RESULT;
                const int64_t digit = byte - 48;
                if (magnitude > (MAX_OPERAND_MAGNITUDE - digit) / 10)
                    return INVALID_RESULT;
                magnitude = magnitude * 10 + digit;
            }
            if (top >= MAX_TOKEN_COUNT) return INVALID_RESULT;
            double value = (double)magnitude;
            if (negative) value = -value;
            stack[top++] = value;
        }

        if (position < length) {
            ++position;
            if (position == length || values[position] == 32) return INVALID_RESULT;
        }
    }
    if (token_count == 0 || top != 1) return INVALID_RESULT;
    const double result = stack[0];
    if (result != result || result < -MAX_INTERMEDIATE_MAGNITUDE ||
        result > MAX_INTERMEDIATE_MAGNITUDE) return INVALID_RESULT;
    return result;
}
