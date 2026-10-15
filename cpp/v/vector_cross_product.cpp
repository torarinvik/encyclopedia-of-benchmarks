// Cross two bounded integer vectors and encode components plus magnitude.
#include <cmath>
#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

extern "C" std::int64_t vector_cross_product(const std::int64_t *input,
        std::size_t input_length, std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length != 6) return -1;
    for (std::size_t i = 0; i < 6; ++i) if (input[i] < -1000000 || input[i] > 1000000) return -1;
    const std::int64_t x = input[1] * input[5] - input[2] * input[4];
    const std::int64_t y = -((input[0] * input[5]) - (input[2] * input[3]));
    const std::int64_t z = input[0] * input[4] - input[1] * input[3];
    const double magnitude = std::sqrt(static_cast<double>(x) * x + static_cast<double>(y) * y + static_cast<double>(z) * z);
    const auto magnitude_micro = static_cast<std::int64_t>(magnitude * 1000000.0 + 0.5);
    if (output == nullptr || output_capacity < 32) return -2;
    store_i64_le(output, 0, x); store_i64_le(output, 8, y);
    store_i64_le(output, 16, z); store_i64_le(output, 24, magnitude_micro);
    return 32;
}
