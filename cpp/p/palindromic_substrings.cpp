// Count all palindromic substrings by expanding around odd and even centers.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t palindromic_substrings(
    const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > 1000 || values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -1;

    std::int64_t count = 0;
    for (std::size_t center = 0; center < length; ++center) {
        ++count;
        std::size_t left = center, right = center;
        while (left > 0 && right + 1 < length &&
               values[left - 1] == values[right + 1]) {
            ++count;
            --left;
            ++right;
        }

        left = center;
        right = center + 1;
        while (right < length && values[left] == values[right]) {
            ++count;
            if (left == 0 || right + 1 == length) break;
            --left;
            ++right;
        }
    }
    return count;
}
