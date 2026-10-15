/* Fletcher-16 checksum for bounded ASCII byte arrays. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxBytes = 4096;
}

extern "C" std::int64_t fletcher16(const std::int64_t *input,
                                    std::size_t length) noexcept {
    if (length > kMaxBytes || (length != 0 && input == nullptr)) return -1;
    std::uint32_t sum1 = 0;
    std::uint32_t sum2 = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto byte = input[index];
        if (byte < 0 || byte > 127) return -1;
        sum1 = (sum1 + static_cast<std::uint32_t>(byte)) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    return static_cast<std::int64_t>((sum2 << 8) | sum1);
}
