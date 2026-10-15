// Copy positive list values, then scan each mirrored twin pair.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 1024; }

extern "C" std::int64_t maximum_twin_sum_of_linked_list(const std::int64_t *values,
    std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_length || length % 2 != 0) return -1;
    std::int32_t copied[max_length];
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || values[index] > 100000) return -1;
        copied[index] = static_cast<std::int32_t>(values[index]);
    }
    std::int64_t maximum = 0;
    for (std::size_t index = 0; index < length / 2; ++index) {
        const auto twin_sum = static_cast<std::int64_t>(copied[index]) + copied[length - index - 1];
        if (twin_sum > maximum) maximum = twin_sum;
    }
    return maximum;
}
