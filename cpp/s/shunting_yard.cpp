#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::size_t max_input_values = 257;
constexpr std::int64_t max_expression_bytes = 255;
constexpr std::size_t max_operands = 16;
constexpr std::size_t max_operators = 15;
constexpr std::size_t max_literal_bytes = 16;
constexpr double max_literal_value = 1000000.0;
constexpr double max_intermediate = 1000000000000.0;

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept
{
    volatile double result = left + right;
    return result;
}

double rounded_divide(double left, double right) noexcept
{
    volatile double result = left / right;
    return result;
}

bool is_ascii_whitespace(std::int64_t value) noexcept
{
    return value == ' ' || value == '\t' || value == '\n' ||
           value == '\v' || value == '\f' || value == '\r';
}

bool is_ascii_digit(std::int64_t value) noexcept
{
    return value >= '0' && value <= '9';
}

bool is_operator(std::int64_t value) noexcept
{
    return value == '+' || value == '-' || value == '*' ||
           value == '/' || value == '^';
}

int precedence(char op) noexcept
{
    if (op == '^') return 3;
    if (op == '*' || op == '/') return 2;
    return 1;
}

bool apply_top(std::array<double, max_operands> &numbers,
               std::size_t &number_count,
               const std::array<char, max_operators> &operators,
               std::size_t &operator_count) noexcept
{
    if (number_count < 2 || operator_count == 0) return false;
    const char op = operators[--operator_count];
    const double right = numbers[--number_count];
    const double left = numbers[--number_count];
    double value;
    switch (op) {
        case '+': value = left + right; break;
        case '-': value = left - right; break;
        case '*': value = left * right; break;
        case '/':
            if (right == 0.0) return false;
            value = left / right;
            break;
        case '^': value = std::pow(left, right); break;
        default: return false;
    }
    if (!std::isfinite(value) || std::fabs(value) > max_intermediate) return false;
    numbers[number_count++] = value;
    return true;
}
}

extern "C" double shunting_yard(const std::int64_t *input,
                                std::size_t input_length) noexcept
{
    if (input == nullptr || input_length < 2 || input_length > max_input_values)
        return invalid_result;
    if (input[0] < 1 || input[0] > max_expression_bytes) return invalid_result;
    const std::size_t byte_count = static_cast<std::size_t>(input[0]);
    if (input_length != byte_count + 1) return invalid_result;
    for (std::size_t i = 0; i < byte_count; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 127) return invalid_result;
    }

    std::array<double, max_operands> numbers{};
    std::array<char, max_operators> operators{};
    std::size_t number_count = 0;
    std::size_t operator_count = 0;
    std::size_t operand_count = 0;
    std::size_t parsed_operator_count = 0;
    std::size_t position = 1;
    bool expect_number = true;

    while (position <= byte_count) {
        while (position <= byte_count && is_ascii_whitespace(input[position])) ++position;
        if (position > byte_count) break;

        if (expect_number) {
            const std::size_t start = position;
            std::size_t integer_digits = 0;
            double value = 0.0;
            while (position <= byte_count && is_ascii_digit(input[position])) {
                value = rounded_add(rounded_multiply(value, 10.0),
                                    static_cast<double>(input[position] - '0'));
                ++integer_digits;
                ++position;
            }
            if (integer_digits == 0) return invalid_result;

            if (position <= byte_count && input[position] == '.') {
                ++position;
                std::size_t fractional_digits = 0;
                double scale = 0.1;
                while (position <= byte_count && is_ascii_digit(input[position])) {
                    const double term = rounded_multiply(
                        static_cast<double>(input[position] - '0'), scale);
                    value = rounded_add(value, term);
                    scale = rounded_divide(scale, 10.0);
                    ++fractional_digits;
                    ++position;
                }
                if (fractional_digits == 0) return invalid_result;
            }

            const std::size_t literal_length = position - start;
            if (literal_length > max_literal_bytes || value < 0.0 ||
                value > max_literal_value || operand_count >= max_operands)
                return invalid_result;
            numbers[number_count++] = value;
            ++operand_count;
            expect_number = false;
        } else {
            const std::int64_t raw_operator = input[position];
            if (!is_operator(raw_operator) || parsed_operator_count >= max_operators)
                return invalid_result;
            const char current = static_cast<char>(raw_operator);
            while (operator_count > 0) {
                const char previous = operators[operator_count - 1];
                const int previous_precedence = precedence(previous);
                const int current_precedence = precedence(current);
                if (previous_precedence < current_precedence ||
                    (previous_precedence == current_precedence && current == '^')) break;
                if (!apply_top(numbers, number_count, operators, operator_count))
                    return invalid_result;
            }
            operators[operator_count++] = current;
            ++position;
            ++parsed_operator_count;
            expect_number = true;
        }
    }

    if (expect_number || operand_count == 0 ||
        parsed_operator_count + 1 != operand_count) return invalid_result;
    while (operator_count > 0) {
        if (!apply_top(numbers, number_count, operators, operator_count))
            return invalid_result;
    }
    if (number_count != 1) return invalid_result;
    return numbers[0];
}
