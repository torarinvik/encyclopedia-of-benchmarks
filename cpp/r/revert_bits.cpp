#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t input_count = 2;
constexpr std::int64_t output_bytes = 12;

std::uint32_t reverse_bits32(std::uint32_t n) {
    n = ((n >> 1) & 0x55555555u) | ((n & 0x55555555u) << 1);
    n = ((n >> 2) & 0x33333333u) | ((n & 0x33333333u) << 2);
    n = ((n >> 4) & 0x0f0f0f0fu) | ((n & 0x0f0f0f0fu) << 4);
    return ((n & 0xff000000u) >> 24) | ((n & 0x00ff0000u) >> 8) |
           ((n & 0x0000ff00u) << 8) | ((n & 0x000000ffu) << 24);
}

std::uint64_t reverse_bits64(std::uint64_t n) {
    n = ((n >> 1) & 0x5555555555555555ull) | ((n & 0x5555555555555555ull) << 1);
    n = ((n >> 2) & 0x3333333333333333ull) | ((n & 0x3333333333333333ull) << 2);
    n = ((n >> 4) & 0x0f0f0f0f0f0f0f0full) | ((n & 0x0f0f0f0f0f0f0f0full) << 4);
    return ((n & 0xff00000000000000ull) >> 56) |
           ((n & 0x00ff000000000000ull) >> 40) |
           ((n & 0x0000ff0000000000ull) >> 24) |
           ((n & 0x000000ff00000000ull) >> 8) |
           ((n & 0x00000000ff000000ull) << 8) |
           ((n & 0x0000000000ff0000ull) << 24) |
           ((n & 0x000000000000ff00ull) << 40) |
           ((n & 0x00000000000000ffull) << 56);
}
}

extern "C" std::int64_t revert_bits(const std::int64_t *input, std::size_t length,
                                   std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != input_count || input[0] < 0 ||
        static_cast<std::uint64_t>(input[0]) > UINT32_MAX) return -1;
    if (output == nullptr || capacity < static_cast<std::size_t>(output_bytes)) return -2;
    const auto reversed32 = reverse_bits32(static_cast<std::uint32_t>(input[0]));
    const auto reversed64 = reverse_bits64(static_cast<std::uint64_t>(input[1]));
    for (std::size_t i = 0; i < 4; ++i) output[i] = static_cast<std::uint8_t>(reversed32 >> (8 * i));
    for (std::size_t i = 0; i < 8; ++i) output[4 + i] = static_cast<std::uint8_t>(reversed64 >> (8 * i));
    return output_bytes;
}
