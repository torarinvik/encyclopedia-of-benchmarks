#include <cstddef>
#include <cstdint>

extern "C" std::int64_t sock_merchant(const std::int64_t *colors, std::size_t length) noexcept
{
    if (length > 512 || (length > 0 && colors == nullptr)) return -1;
    std::size_t counts[4096] = {};
    for (std::size_t i = 0; i < length; ++i) {
        if (colors[i] < 0 || colors[i] >= 4096) return -1;
        ++counts[static_cast<std::size_t>(colors[i])];
    }
    std::size_t pairs = 0;
    for (std::size_t color = 0; color < 4096; ++color) pairs += counts[color] / 2;
    return static_cast<std::int64_t>(pairs);
}
