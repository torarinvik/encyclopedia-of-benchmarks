#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 1024;
constexpr std::int64_t kMaxAbsValue = 1'000'000;
}

extern "C" std::int64_t maximum_subarray_int32(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > kMaxLength) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -kMaxAbsValue || values[index] > kMaxAbsValue) return -1;
    }
    auto current = values[0];
    auto best = current;
    for (std::size_t index = 1; index < length; ++index) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
