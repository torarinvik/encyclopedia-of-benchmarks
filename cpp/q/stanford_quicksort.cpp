#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t SORT_ELEMENTS = 5000;
constexpr std::int64_t MAX_PREFIX_COUNT = 100;
constexpr std::size_t MAX_OUTPUT_BYTES = 700;

void source_quicksort(std::int64_t *values, std::int64_t left, std::int64_t right)
{
    std::int64_t i = left;
    std::int64_t j = right;
    const std::int64_t pivot = values[(left + right) / 2];
    do {
        while (values[i] < pivot) ++i;
        while (pivot < values[j]) --j;
        if (i <= j) {
            const auto temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
            ++i;
            --j;
        }
    } while (i <= j);
    if (left < j) source_quicksort(values, left, j);
    if (i < right) source_quicksort(values, i, right);
}

std::size_t append_number(std::uint8_t *buffer, std::size_t used, std::int64_t value)
{
    std::uint8_t reversed[20];
    std::size_t count = 0;
    if (value < 0) {
        buffer[used++] = static_cast<std::uint8_t>('-');
        value = -value;
    }
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[used++] = reversed[--count];
    buffer[used++] = static_cast<std::uint8_t>('\n');
    return used;
}
}

extern "C" std::int64_t stanford_quicksort(std::int64_t prefix_count,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (prefix_count < 1 || prefix_count > MAX_PREFIX_COUNT) return -1;
    if (output == nullptr) return -2;

    std::uint8_t staged[MAX_OUTPUT_BYTES];
    std::size_t used = 0;
    for (std::int64_t run = 0; run < prefix_count; ++run) {
        std::int64_t values[SORT_ELEMENTS + 1];
        std::int64_t state = 74755;
        for (std::int64_t index = 1; index <= SORT_ELEMENTS; ++index) {
            state = (state * 1309 + 13849) & 65535;
            values[index] = state - 50000;
        }
        source_quicksort(values, 1, SORT_ELEMENTS);
        used = append_number(staged, used, values[run + 1]);
    }

    if (output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
