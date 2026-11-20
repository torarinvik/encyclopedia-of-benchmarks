#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaximumDegree = 4;
constexpr std::size_t kMaximumParseableLength = 7;
}

extern "C" std::int64_t routh_hurwitz_stability_predicate(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > kMaximumParseableLength) return -1;
    const auto degree = input[0];
    if (degree < 1 || degree > kMaximumDegree || length != static_cast<std::size_t>(degree) + 2U) return -1;

    std::int64_t coefficients[5] = {};
    for (std::int64_t index = 0; index <= degree; ++index) {
        const auto value = input[static_cast<std::size_t>(index) + 1U];
        if (value < -3 || value > 3 || (index == 0 && value <= 0)) return -1;
        coefficients[index] = value;
    }

    const auto width = static_cast<std::size_t>(degree + 2) / 2U;
    std::int64_t table[5][3] = {};
    for (std::size_t column = 0; column < width; ++column) {
        const auto even_index = 2U * column;
        const auto odd_index = even_index + 1U;
        if (even_index <= static_cast<std::size_t>(degree)) table[0][column] = coefficients[even_index];
        if (odd_index <= static_cast<std::size_t>(degree)) table[1][column] = coefficients[odd_index];
    }

    bool row_one_is_zero = true;
    for (std::size_t column = 0; column < width; ++column) {
        row_one_is_zero = row_one_is_zero && table[1][column] == 0;
    }
    if (row_one_is_zero || table[1][0] <= 0) return 0;

    for (std::size_t row = 2; row <= static_cast<std::size_t>(degree); ++row) {
        if (table[row - 1U][0] <= 0) return 0;
        bool all_zero = true;
        for (std::size_t column = 0; column < width; ++column) {
            const auto upper_next = column + 1U < width ? table[row - 2U][column + 1U] : 0;
            const auto lower_next = column + 1U < width ? table[row - 1U][column + 1U] : 0;
            table[row][column] = table[row - 1U][0] * upper_next
                               - table[row - 2U][0] * lower_next;
            all_zero = all_zero && table[row][column] == 0;
        }
        if (all_zero || table[row][0] <= 0) return 0;
    }
    return 1;
}
