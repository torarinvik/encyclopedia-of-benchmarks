/* Stable bottom-up merge sort using caller-provided scratch storage. */
#include <cstddef>
#include <cstdint>

extern "C" void merge_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    for (std::size_t width = 1; width < length;) {
        std::size_t low = 0;
        while (low < length) {
            std::size_t middle = low + width;
            if (middle > length) middle = length;
            std::size_t high = middle + width;
            if (high > length) high = length;
            std::size_t left = low;
            std::size_t right = middle;
            std::size_t output = low;
            while (left < middle && right < high) {
                if (values[left] <= values[right]) scratch[output++] = values[left++];
                else scratch[output++] = values[right++];
            }
            while (left < middle) scratch[output++] = values[left++];
            while (right < high) scratch[output++] = values[right++];
            for (std::size_t index = low; index < high; ++index) values[index] = scratch[index];
            low = high;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
