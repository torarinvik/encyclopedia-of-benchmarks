#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 8;
constexpr std::int64_t invalid_result = -1;

bool is_sorted(const std::int64_t *values, std::size_t length) noexcept {
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index - 1] > values[index]) return false;
    }
    return true;
}
}

extern "C" std::int64_t permutation_sort(const std::int64_t *values,
                                         std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return invalid_result;

    std::int64_t working[max_length]{};
    std::size_t counters[max_length]{};
    for (std::size_t index = 0; index < length; ++index) working[index] = values[index];

    std::int64_t checked = 1;
    if (is_sorted(working, length)) return checked;

    std::size_t index = 0;
    while (index < length) {
        if (counters[index] < index) {
            const std::size_t swap_index = (index % 2 == 0) ? 0 : counters[index];
            const std::int64_t temporary = working[swap_index];
            working[swap_index] = working[index];
            working[index] = temporary;
            ++counters[index];
            ++checked;
            if (is_sorted(working, length)) return checked;
            index = 0;
        } else {
            counters[index] = 0;
            ++index;
        }
    }
    return invalid_result;
}
