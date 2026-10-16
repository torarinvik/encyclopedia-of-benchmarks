#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 1024;
}

extern "C" std::int64_t maximum_subarray_allow_empty(const std::int64_t *values,
                                                      std::size_t length) noexcept
{
    if (length > kMaxLength || (length > 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    std::int64_t current = 0;
    std::int64_t best = 0;
    for (std::size_t index = 0; index < length; ++index) {
        current += values[index];
        if (current < 0) current = 0;
        if (current > best) best = current;
    }
    return best;
}
