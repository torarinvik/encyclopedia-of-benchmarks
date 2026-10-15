/* Find the leftmost longest ASCII alphanumeric palindrome by expanding centers. */
#include <cstddef>
#include <cstdint>

static bool is_ascii_alphanumeric(std::int64_t value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

extern "C" std::int64_t longest_palindromic_substring(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 1000 || values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    std::size_t best_start = 0;
    std::size_t best_length = 1;
    for (std::size_t center = 0; center < length; ++center) {
        std::size_t left = center, right = center;
        while (left > 0 && right + 1 < length &&
               values[left - 1] == values[right + 1]) {
            --left;
            ++right;
        }
        std::size_t candidate_length = right - left + 1;
        if (candidate_length > best_length) {
            best_start = left;
            best_length = candidate_length;
        }

        left = center;
        right = center + 1;
        while (right < length && values[left] == values[right]) {
            candidate_length = right - left + 1;
            if (candidate_length > best_length) {
                best_start = left;
                best_length = candidate_length;
            }
            if (left == 0 || right + 1 == length) break;
            --left;
            ++right;
        }
    }

    if (output_capacity < best_length || output == nullptr) return -2;
    for (std::size_t index = 0; index < best_length; ++index)
        output[index] = static_cast<std::uint8_t>(values[best_start + index]);
    return static_cast<std::int64_t>(best_length);
}
