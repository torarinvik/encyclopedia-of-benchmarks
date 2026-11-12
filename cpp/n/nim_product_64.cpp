#include <cstddef>
#include <cstdint>

namespace {
std::uint64_t nim_product(std::uint64_t a, std::uint64_t b, unsigned width) noexcept {
    if (width == 1) return a & b;
    const unsigned half = width / 2;
    const std::uint64_t mask = (UINT64_C(1) << half) - UINT64_C(1);
    const std::uint64_t a_low = a & mask;
    const std::uint64_t a_high = a >> half;
    const std::uint64_t b_low = b & mask;
    const std::uint64_t b_high = b >> half;
    const std::uint64_t low_product = nim_product(a_low, b_low, half);
    const std::uint64_t high_product = nim_product(a_high, b_high, half);
    const std::uint64_t cross = nim_product(a_low ^ a_high, b_low ^ b_high, half)
                              ^ low_product ^ high_product;
    const std::uint64_t constant = UINT64_C(1) << (half - 1);
    const std::uint64_t low = low_product ^ nim_product(high_product, constant, half);
    const std::uint64_t high = cross ^ high_product;
    return low ^ (high << half);
}
} // namespace

extern "C" std::int64_t nim_product_64(const std::int64_t* input,
                                        std::size_t length,
                                        std::uint8_t* output,
                                        std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 4) return -1;
    for (std::size_t index = 0; index < 4; ++index)
        if (input[index] < 0 || input[index] > INT64_C(4294967295)) return -1;
    if (output == nullptr || output_capacity < 8) return -2;

    const std::uint64_t a = static_cast<std::uint64_t>(input[0])
                          | (static_cast<std::uint64_t>(input[1]) << 32);
    const std::uint64_t b = static_cast<std::uint64_t>(input[2])
                          | (static_cast<std::uint64_t>(input[3]) << 32);
    const std::uint64_t result = nim_product(a, b, 64);
    for (unsigned index = 0; index < 8; ++index)
        output[index] = static_cast<std::uint8_t>(result >> (8 * index));
    return 8;
}
