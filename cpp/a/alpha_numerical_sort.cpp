// Compare lowercase ASCII alphanumeric strings in natural order.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -2;
bool is_digit(std::int64_t value) { return value >= '0' && value <= '9'; }
bool valid_string(const std::int64_t *input, std::size_t start, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[start + i];
        if (!is_digit(value) && (value < 'a' || value > 'z')) return false;
        if (value == '0' && i > 0 && is_digit(input[start + i - 1])) return false;
    }
    return true;
}
}
extern "C" std::int64_t alpha_numerical_sort(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 64) return INVALID_RESULT;
    const auto first_length = static_cast<std::size_t>(input[0]);
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64) return INVALID_RESULT;
    const auto second_length = static_cast<std::size_t>(input[1 + first_length]);
    if (length != 2 + first_length + second_length || !valid_string(input, 2, first_length)
        || !valid_string(input, 2 + first_length, second_length)) return INVALID_RESULT;
    std::size_t i = 0, j = 0;
    while (i < first_length && j < second_length) {
        const auto a = input[2 + i], b = input[2 + first_length + j];
        if (is_digit(a) && is_digit(b)) {
            std::size_t end_a = i, end_b = j;
            while (end_a < first_length && is_digit(input[2 + end_a])) ++end_a;
            while (end_b < second_length && is_digit(input[2 + first_length + end_b])) ++end_b;
            const auto digits_a = end_a - i, digits_b = end_b - j;
            if (digits_a != digits_b) return digits_a < digits_b ? -1 : 1;
            for (std::size_t k = 0; k < digits_a; ++k) {
                const auto ca = input[2 + i + k], cb = input[2 + first_length + j + k];
                if (ca != cb) return ca < cb ? -1 : 1;
            }
            i = end_a; j = end_b;
        } else {
            if (a != b) return a < b ? -1 : 1;
            ++i; ++j;
        }
    }
    if (i == first_length && j == second_length) return 0;
    return i == first_length ? -1 : 1;
}
