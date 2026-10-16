#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 128;
constexpr std::size_t alphabet_size = 95;
constexpr double invalid_result = -1.0e300;
}

extern "C" double dice_coefficient(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return invalid_result;
    const auto len_a_raw = values[0];
    const auto len_b_raw = values[1];
    if (len_a_raw < 0 || len_a_raw > static_cast<std::int64_t>(max_string_length) ||
        len_b_raw < 0 || len_b_raw > static_cast<std::int64_t>(max_string_length)) return invalid_result;
    const auto len_a = static_cast<std::size_t>(len_a_raw);
    const auto len_b = static_cast<std::size_t>(len_b_raw);
    if (length != 2 + len_a + len_b) return invalid_result;
    for (std::size_t i = 0; i < len_a + len_b; ++i)
        if (values[2 + i] < 32 || values[2 + i] > 126) return invalid_result;
    bool equal = len_a == len_b;
    for (std::size_t i = 0; equal && i < len_a; ++i)
        equal = values[2 + i] == values[2 + len_a + i];
    if (equal) return 1.0;
    if (len_a < 2 || len_b < 2) return 0.0;

    bool present[alphabet_size][alphabet_size]{};
    for (std::size_t i = 0; i + 1 < len_a; ++i) {
        const auto first = static_cast<std::size_t>(values[2 + i] - 32);
        const auto second = static_cast<std::size_t>(values[2 + i + 1] - 32);
        present[first][second] = true;
    }
    std::size_t common = 0;
    for (std::size_t i = 0; i + 1 < len_b; ++i) {
        const auto first = static_cast<std::size_t>(values[2 + len_a + i] - 32);
        const auto second = static_cast<std::size_t>(values[2 + len_a + i + 1] - 32);
        if (present[first][second]) ++common;
    }
    const double denominator = static_cast<double>(len_a - 1 + len_b - 1);
    const double score = (2.0 * static_cast<double>(common)) / denominator;
    return std::floor(score * 100.0) / 100.0;
}
