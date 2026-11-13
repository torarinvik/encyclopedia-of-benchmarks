#include <array>
#include <cstddef>
#include <cstdint>

namespace {
std::uint16_t reduce(std::uint32_t value) noexcept {
    for (int bit = 31; bit >= 16; --bit)
        if (value & (std::uint32_t{1} << bit)) value ^= std::uint32_t{0x1100b} << (bit - 16);
    return static_cast<std::uint16_t>(value);
}
}

extern "C" std::int64_t rabin_content_defined_chunking(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 1 || length > 65 || input[0] < 0 || input[0] > 64) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    std::array<std::uint16_t, 256> outgoing{};
    for (std::size_t i = 0; i < outgoing.size(); ++i) outgoing[i] = reduce(static_cast<std::uint32_t>(i) << 24);
    std::uint16_t fingerprint = 0;
    std::array<std::uint8_t, 64> boundaries{};
    std::size_t count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        fingerprint = reduce((static_cast<std::uint32_t>(fingerprint) << 8) | static_cast<std::uint32_t>(input[i + 1]));
        if (i >= 4) fingerprint ^= outgoing[static_cast<std::size_t>(input[i - 3])];
        if ((fingerprint & 7) == 0) boundaries[count++] = static_cast<std::uint8_t>(i + 1);
    }
    if (n && (!count || boundaries[count - 1] != n)) boundaries[count++] = static_cast<std::uint8_t>(n);
    if (!output || capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = boundaries[i];
    return static_cast<std::int64_t>(count);
}
