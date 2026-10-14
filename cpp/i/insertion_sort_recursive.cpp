/* Stable recursive insertion sort over signed 64-bit values. */
#include <cstddef>
#include <cstdint>

static void insertion_sort_prefix(std::int64_t *values, std::size_t length) noexcept {
    if (length <= 1) return;
    insertion_sort_prefix(values, length - 1);
    const std::int64_t key = values[length - 1];
    std::size_t position = length - 1;
    while (position > 0 && values[position - 1] > key) {
        values[position] = values[position - 1];
        --position;
    }
    values[position] = key;
}

extern "C" void insertion_sort_recursive(std::int64_t *values,
                                            std::size_t length) noexcept {
    insertion_sort_prefix(values, length);
}
