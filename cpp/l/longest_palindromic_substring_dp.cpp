// Find the rightmost longest ASCII alphanumeric palindrome with gap-based DP.
#include <cstddef>
#include <cstdint>
#include <new>

namespace {
constexpr std::size_t max_length = 1000;

bool is_ascii_alphanumeric(std::int64_t value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}
}

extern "C" std::int64_t longest_palindromic_substring_dp(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length == 0 || length > max_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    bool *palindrome = new (std::nothrow) bool[length * length];
    if (palindrome == nullptr) return -1;
    std::size_t best_start = 0;
    std::size_t best_end = 0;
    for (std::size_t gap = 0; gap < length; ++gap) {
        for (std::size_t start = 0, end = gap; end < length; ++start, ++end) {
            bool is_palindrome;
            if (gap == 0) {
                is_palindrome = true;
            } else if (gap == 1) {
                is_palindrome = values[start] == values[end];
            } else {
                is_palindrome = values[start] == values[end] && palindrome[(start + 1) * length + end - 1];
            }
            palindrome[start * length + end] = is_palindrome;
            if (is_palindrome) {
                best_start = start;
                best_end = end;
            }
        }
    }

    const std::size_t best_length = best_end - best_start + 1;
    if (output == nullptr || output_capacity < best_length) {
        delete[] palindrome;
        return -2;
    }
    for (std::size_t index = 0; index < best_length; ++index)
        output[index] = static_cast<std::uint8_t>(values[best_start + index]);
    delete[] palindrome;
    return static_cast<std::int64_t>(best_length);
}
