#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 16;
constexpr std::size_t max_input = 34;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t composition_of_formal_power_series(const std::int64_t* input,
                                                            std::size_t length,
                                                            std::uint8_t* output,
                                                            std::size_t capacity)
{
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1 + n] != 0) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, max_n> composed{};
    for (std::size_t outer = n; outer > 0; --outer) {
        for (std::size_t bound = n; bound > 1; --bound) {
            const auto degree = bound - 1;
            std::int64_t sum = 0;
            for (std::size_t inner_degree = 1; inner_degree <= degree; ++inner_degree)
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % modulus;
            composed[degree] = sum;
        }
        composed[0] = input[outer];
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, composed[i]);
    return static_cast<std::int64_t>(bytes);
}
