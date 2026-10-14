/* Portable 0-based max-heap sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

static void sift_down(std::int64_t *values, std::size_t root, std::size_t end) noexcept
{
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const std::int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

extern "C" void heap_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t start = length / 2; start > 0;) {
        --start;
        sift_down(values, start, length);
    }
    for (std::size_t end = length; end > 1;) {
        --end;
        const std::int64_t temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}
