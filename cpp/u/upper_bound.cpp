#include <cstddef>
#include <cstdint>

namespace {
std::int64_t upper_bound_range(const std::int64_t *values, std::int64_t target,
                               std::int64_t left, std::int64_t right) noexcept {
    if (right <= left) return left;
    const std::int64_t middle = (left + right) / 2;
    if (target < values[middle + 1])
        return upper_bound_range(values, target, left, middle);
    return upper_bound_range(values, target, middle + 1, right);
}
}

extern "C" std::int64_t upper_bound(const std::int64_t *values,
                                     std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > 513) return -1;
    const std::int64_t target = values[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    const std::size_t array_length = length - 1;
    for (std::size_t i = 0; i < array_length; ++i) {
        const std::int64_t value = values[i + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (i != 0 && values[i] > value) return -1;
    }
    return upper_bound_range(values, target, 0,
                             static_cast<std::int64_t>(array_length) - 1);
}
