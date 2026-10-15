#include <cstddef>
#include <cstdint>

namespace {
std::int64_t upper_bound_range(const std::int64_t *values, std::int64_t target,
                               std::int64_t left, std::int64_t right) noexcept {
    if (right <= left) return left;
    const std::int64_t middle = (left + right) / 2;
    if (target < values[middle]) return upper_bound_range(values, target, left, middle);
    return upper_bound_range(values, target, middle + 1, right);
}
}

extern "C" std::int64_t upper_bound(const std::int64_t *values,
                                     std::size_t length,
                                     std::int64_t target) noexcept {
    if (length > 512 || target < INT32_MIN || target > INT32_MAX) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
        if (i != 0 && values[i - 1] > values[i]) return -1;
    }
    return upper_bound_range(values, target, 0, static_cast<std::int64_t>(length) - 1);
}
