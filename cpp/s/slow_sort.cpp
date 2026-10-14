/* SlowSort over an inclusive interval, following the Java source contract. */
#include <cstddef>
#include <cstdint>

namespace {
void slow_sort_range(std::int64_t *values, std::size_t first, std::size_t last) noexcept
{
    if (first >= last) return;
    const std::size_t middle = first + (last - first) / 2;
    slow_sort_range(values, first, middle);
    slow_sort_range(values, middle + 1, last);
    if (values[last] < values[middle]) {
        const std::int64_t temporary = values[last];
        values[last] = values[middle];
        values[middle] = temporary;
    }
    slow_sort_range(values, first, last - 1);
}
} // namespace

extern "C" void slow_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) slow_sort_range(values, 0, length - 1);
}
