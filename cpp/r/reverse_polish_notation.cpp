#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 255;
constexpr std::size_t max_parseable_input_length = 256;
constexpr std::size_t max_token_count = 63;
constexpr std::int64_t max_operand_magnitude = 1'000'000;
constexpr double max_intermediate_magnitude = 1.0e200;
constexpr double invalid_result = -1.0e300;
}

extern "C" double reverse_polish_notation(const std::int64_t *values,
                                         std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_parseable_input_length)
        return invalid_result;
    if (length > max_input_length) return invalid_result;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return invalid_result;

    double stack[max_token_count]{};
    std::size_t top = 0, position = 0, token_count = 0;
    while (position < length) {
        const std::size_t token_start = position;
        while (position < length && values[position] != 32) ++position;
        const std::size_t token_length = position - token_start;
        if (token_length == 0 || ++token_count > max_token_count) return invalid_result;

        const std::int64_t token = values[token_start];
        const bool is_operator = token_length == 1 &&
            (token == 43 || token == 45 || token == 42 || token == 47);
        if (is_operator) {
            if (top < 2) return invalid_result;
            const double a = stack[top - 1];
            const double b = stack[top - 2];
            double result;
            if (token == 43) result = a + b;
            else if (token == 45) result = a - b;
            else if (token == 42) result = a * b;
            else {
                if (a == 0.0) return invalid_result;
                result = b / a;
            }
            if (result != result || result < -max_intermediate_magnitude ||
                result > max_intermediate_magnitude) return invalid_result;
            stack[top - 2] = result;
            --top;
        } else {
            std::size_t number_position = token_start;
            bool negative = false;
            if (values[number_position] == 43 || values[number_position] == 45) {
                negative = values[number_position] == 45;
                ++number_position;
            }
            if (number_position == position) return invalid_result;

            std::int64_t magnitude = 0;
            while (number_position < position) {
                const std::int64_t byte = values[number_position++];
                if (byte < 48 || byte > 57) return invalid_result;
                const std::int64_t digit = byte - 48;
                if (magnitude > (max_operand_magnitude - digit) / 10)
                    return invalid_result;
                magnitude = magnitude * 10 + digit;
            }
            if (top >= max_token_count) return invalid_result;
            double value = static_cast<double>(magnitude);
            if (negative) value = -value;
            stack[top++] = value;
        }

        if (position < length) {
            ++position;
            if (position == length || values[position] == 32) return invalid_result;
        }
    }
    if (token_count == 0 || top != 1) return invalid_result;
    const double result = stack[0];
    if (result != result || result < -max_intermediate_magnitude ||
        result > max_intermediate_magnitude) return invalid_result;
    return result;
}
