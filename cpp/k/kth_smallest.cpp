// One-based quickselect using the pinned last-element partition.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 256;

std::size_t partition_values(std::int32_t *values, std::size_t low, std::size_t high) noexcept {
    const std::size_t pivot = high;
    std::size_t i = low;
    std::size_t j = high - 1;
    for (;;) {
        while (values[i] < values[pivot]) ++i;
        while (j > 0 && values[j] > values[pivot]) --j;
        if (j == 0 || i >= j) break;
        if (values[i] == values[j]) {
            ++i;
            --j;
        } else {
            const auto temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    const auto temporary = values[i];
    values[i] = values[pivot];
    values[pivot] = temporary;
    return i;
}
}

extern "C" std::int64_t kth_smallest(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_length + 2) return std::numeric_limits<std::int64_t>::min();
    const auto n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_length) || k_value < 1 || k_value > n_value ||
        length != static_cast<std::size_t>(n_value) + 2) return std::numeric_limits<std::int64_t>::min();
    const auto n = static_cast<std::size_t>(n_value);
    std::int32_t values[max_length];
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = input[index + 2];
        if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max())
            return std::numeric_limits<std::int64_t>::min();
        values[index] = static_cast<std::int32_t>(value);
    }

    std::size_t low = 0, high = n - 1, k = static_cast<std::size_t>(k_value);
    while (low < high) {
        const auto pivot = partition_values(values, low, high);
        const auto pivot_rank = pivot - low + 1;
        if (k == pivot_rank) return values[pivot];
        if (k < pivot_rank) {
            high = pivot - 1;
        } else {
            low = pivot + 1;
            k -= pivot_rank;
        }
    }
    return values[low];
}
