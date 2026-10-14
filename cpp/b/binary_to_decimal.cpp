/* Convert a packed most-significant-first binary digit array to signed i64. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_to_decimal(const std::int64_t *bits,
                                            std::size_t length) noexcept
{
    if (length == 0 || length > 63 || bits == nullptr) return -1;
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (bits[index] != 0 && bits[index] != 1) return -1;
        value = value * 2 + static_cast<std::uint64_t>(bits[index]);
    }
    return static_cast<std::int64_t>(value);
}
