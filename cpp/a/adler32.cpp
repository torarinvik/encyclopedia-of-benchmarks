#include <cstddef>
#include <cstdint>

extern "C" std::int64_t adler32(const std::int64_t *values, std::size_t length)
{
    if (length > 100001 || (length != 0 && values == nullptr)) return -1;

    std::uint32_t a = 1;
    std::uint32_t b = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 0 || value > 255) return -1;
        a = (a + static_cast<std::uint32_t>(value)) % UINT32_C(65521);
        b = (b + a) % UINT32_C(65521);
    }

    return static_cast<std::int64_t>((b << 16) | a);
}
