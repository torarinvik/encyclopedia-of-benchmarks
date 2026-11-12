#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input = 66;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t polynomial_taylor_shift(const std::int64_t* input,
                                                    std::size_t length,
                                                    std::uint8_t* output,
                                                    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto shift = input[1];
    if (length != n + 2 || shift < 0 || shift >= modulus) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= modulus) return -1;

    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, max_n> shifted{};
    std::size_t processed = 0;
    for (std::size_t source = n; source > 0; --source) {
        for (std::size_t degree = processed; degree > 0; --degree)
            shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % modulus;
        shifted[0] = (shifted[0] * shift + input[source + 1]) % modulus;
        ++processed;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, shifted[i]);
    return static_cast<std::int64_t>(bytes);
}
