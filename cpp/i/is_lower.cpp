#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
}

extern "C" std::int64_t is_lower(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 'A' && value <= 'Z') return 0;
    }
    return 1;
}
