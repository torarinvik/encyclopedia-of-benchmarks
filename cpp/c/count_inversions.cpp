/* Count strict inversions with bottom-up merge sort. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_inversions(const std::int64_t *values,
                                          std::size_t length) noexcept
{
    constexpr std::size_t max_length = 4096;
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    if (length < 2) return 0;

    std::int64_t source[max_length];
    std::int64_t scratch[max_length];
    for (std::size_t i = 0; i < length; ++i) source[i] = values[i];

    std::int64_t inversions = 0;
    for (std::size_t width = 1; width < length; width *= 2) {
        for (std::size_t low = 0; low < length;) {
            std::size_t middle = low + width;
            if (middle > length) middle = length;
            std::size_t high = middle + width;
            if (high > length) high = length;
            std::size_t left = low, right = middle, out = low;
            while (left < middle && right < high) {
                if (source[left] <= source[right]) {
                    scratch[out++] = source[left++];
                } else {
                    scratch[out++] = source[right++];
                    inversions += static_cast<std::int64_t>(middle - left);
                }
            }
            while (left < middle) scratch[out++] = source[left++];
            while (right < high) scratch[out++] = source[right++];
            low = high;
        }
        for (std::size_t i = 0; i < length; ++i) source[i] = scratch[i];
    }
    return inversions;
}
