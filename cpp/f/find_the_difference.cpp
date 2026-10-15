// Return the lowercase byte added to t by subtracting the two character sums.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 4096;
constexpr std::size_t max_packed_length = 2 + 2 * max_string_length + 1;
}

extern "C" std::int64_t find_the_difference(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_packed_length) return -1;
    if (input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 4097) return -1;
    const auto s_length = static_cast<std::size_t>(input[0]);
    const auto t_length = static_cast<std::size_t>(input[1]);
    if (t_length != s_length + 1 || length != 2 + s_length + t_length) return -1;
    std::int64_t sum_s = 0, sum_t = 0;
    for (std::size_t index = 0; index < s_length; ++index) {
        const auto value = input[2 + index];
        if (value < 97 || value > 122) return -1;
        sum_s += value;
    }
    const auto t_start = 2 + s_length;
    for (std::size_t index = 0; index < t_length; ++index) {
        const auto value = input[t_start + index];
        if (value < 97 || value > 122) return -1;
        sum_t += value;
    }
    const auto difference = sum_t - sum_s;
    return difference >= 97 && difference <= 122 ? difference : -1;
}
