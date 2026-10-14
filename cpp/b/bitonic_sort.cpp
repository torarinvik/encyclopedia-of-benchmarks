/* Portable bitonic sorting network for power-of-two lengths. */
#include <cstddef>
#include <cstdint>

static void bitonic_compare(std::int64_t *values, std::size_t left, std::size_t right, bool ascending) noexcept
{
    if ((ascending && values[left] > values[right]) || (!ascending && values[left] < values[right])) {
        const std::int64_t temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

static void bitonic_merge(std::int64_t *values, std::size_t low, std::size_t length, bool ascending) noexcept
{
    if (length < 2) return;
    const std::size_t half = length / 2;
    for (std::size_t index = low; index < low + half; ++index) {
        bitonic_compare(values, index, index + half, ascending);
    }
    bitonic_merge(values, low, half, ascending);
    bitonic_merge(values, low + half, half, ascending);
}

static void bitonic_sort_range(std::int64_t *values, std::size_t low, std::size_t length, bool ascending) noexcept
{
    if (length < 2) return;
    const std::size_t half = length / 2;
    bitonic_sort_range(values, low, half, true);
    bitonic_sort_range(values, low + half, half, false);
    bitonic_merge(values, low, length, ascending);
}

extern "C" void bitonic_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    bitonic_sort_range(values, 0, length, true);
}
