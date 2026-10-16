#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxValues = 25;
constexpr std::size_t kMaxInputLength = 28;

void insertion_sort(std::int64_t *values, std::size_t start, std::size_t end)
{
    for (std::size_t index = start + 1; index < end; ++index) {
        const std::int64_t value = values[index];
        std::size_t position = index;
        while (position > start && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

std::int64_t select_kth(std::int64_t *values, std::size_t length, std::size_t rank)
{
    std::int64_t medians[5];
    std::size_t median_count = 0;
    for (std::size_t start = 0; start < length; start += 5) {
        const std::size_t end = start + 5 < length ? start + 5 : length;
        insertion_sort(values, start, end);
        medians[median_count++] = values[(start + end) / 2];
    }
    insertion_sort(medians, 0, median_count);
    const std::int64_t pivot = medians[(median_count - 1) / 2];

    std::int64_t lower[kMaxValues], higher[kMaxValues];
    std::size_t lower_count = 0, higher_count = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < pivot) lower[lower_count++] = values[index];
        else if (values[index] > pivot) higher[higher_count++] = values[index];
    }
    if (rank < lower_count) return select_kth(lower, lower_count, rank);
    if (rank > lower_count) return select_kth(higher, higher_count, rank - lower_count - 1);
    return pivot;
}
} // namespace

extern "C" std::int64_t median_of_medians(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInputLength) return -1;
    const std::int64_t count_value = input[0], rank_value = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(kMaxValues) ||
        rank_value < 0 || rank_value >= count_value ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;

    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t values[kMaxValues];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 2];
        if (value < 0 || value > INT32_MAX) return -1;
        for (std::size_t previous = 0; previous < index; ++previous) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(values, count, static_cast<std::size_t>(rank_value));
}
