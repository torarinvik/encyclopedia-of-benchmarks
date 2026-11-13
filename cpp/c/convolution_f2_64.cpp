#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8, max_m = 8, max_parseable = 19;

std::uint64_t multiply_in_field(std::uint64_t left, std::uint64_t right) noexcept {
    std::uint64_t result = 0;
    for (unsigned bit = 0; bit < 64; ++bit) {
        if ((right & 1U) != 0) result ^= left;
        const bool leading = (left >> 63) != 0;
        left <<= 1;
        if (leading) left ^= UINT64_C(0x1b);
        right >>= 1;
    }
    return result;
}
}  // namespace

extern "C" std::int64_t convolution_f2_64(const std::int64_t* input,
        std::size_t length, std::uint8_t* output,
        std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)
            || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;

    const std::size_t count = n + m - 1, needed = 8 * count;
    if (output == nullptr || output_capacity < needed) return -2;
    std::array<std::uint64_t, max_n> a{};
    std::array<std::uint64_t, max_m> b{};
    std::array<std::uint64_t, max_n + max_m - 1> result{};
    for (std::size_t i = 0; i < n; ++i) a[i] = static_cast<std::uint64_t>(input[2 + i]);
    for (std::size_t j = 0; j < m; ++j) b[j] = static_cast<std::uint64_t>(input[2 + n + j]);
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < m; ++j)
            result[i + j] ^= multiply_in_field(a[i], b[j]);
    for (std::size_t i = 0; i < count; ++i)
        for (unsigned byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = static_cast<std::uint8_t>(result[i] >> (8 * byte));
    return static_cast<std::int64_t>(needed);
}
