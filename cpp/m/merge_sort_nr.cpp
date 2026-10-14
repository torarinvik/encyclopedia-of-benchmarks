#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
}

extern "C" void merge_sort_nr(std::int64_t *values, std::size_t length)
{
    if (length > max_values) {
        return;
    }

    std::int64_t scratch[max_values];
    for (std::size_t width = 1; width < length; width *= 2) {
        for (std::size_t start = 0; start < length; start += width * 2) {
            std::size_t middle = start + width;
            if (middle > length) {
                middle = length;
            }
            std::size_t end = middle + width;
            if (end > length) {
                end = length;
            }

            std::size_t left = start;
            std::size_t right = middle;
            std::size_t output = start;
            while (left < middle && right < end) {
                scratch[output++] = values[left] <= values[right]
                    ? values[left++] : values[right++];
            }
            while (left < middle) {
                scratch[output++] = values[left++];
            }
            while (right < end) {
                scratch[output++] = values[right++];
            }
        }
        for (std::size_t index = 0; index < length; ++index) {
            values[index] = scratch[index];
        }
    }
}
