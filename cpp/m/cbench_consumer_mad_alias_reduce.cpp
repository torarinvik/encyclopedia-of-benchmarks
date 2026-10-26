#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::array<std::int64_t, 8> kCs{
    0x0db84a81LL, 0x0e1b9d7fLL, 0x0f31adcfLL, 0x0fbba815LL,
    0x0feda417LL, 0x0ffc8fc8LL, 0x0fff964cLL, 0x0ffff8d3LL};
constexpr std::array<std::int64_t, 8> kCa{
    -0x083b5fe7LL, -0x078c36d2LL, -0x05039814LL, -0x02e91dd1LL,
    -0x0183603aLL, -0x00a7cb87LL, -0x003a2847LL, -0x000f27b4LL};

std::int64_t floor_div(std::int64_t value, std::int64_t divisor) {
    auto quotient = value / divisor;
    if (value % divisor < 0) --quotient;
    return quotient;
}
std::int64_t mad_mul(std::int64_t left, std::int64_t right) {
    return floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536);
}
}

extern "C" std::int64_t cbench_consumer_mad_alias_reduce(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 1 || length > 65 || input[0] < 1 || input[0] > 4) return -1;
    const auto boundaries = static_cast<std::size_t>(input[0]);
    if (length != 1 + 16 * boundaries) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < -100000000LL || input[i] > 100000000LL) return -1;
    const auto output_size = 64 * boundaries;
    std::array<std::int32_t, 64> staged{};
    for (std::size_t boundary = 0; boundary < boundaries; ++boundary) {
        const auto base = 1 + 16 * boundary;
        for (std::size_t i = 0; i < 8; ++i) {
            const auto a = input[base + 2 * i], b = input[base + 2 * i + 1];
            staged[16 * boundary + 2 * i] = static_cast<std::int32_t>(mad_mul(a, kCs[i]) + mad_mul(-b, kCa[i]));
            staged[16 * boundary + 2 * i + 1] = static_cast<std::int32_t>(mad_mul(b, kCs[i]) + mad_mul(a, kCa[i]));
        }
    }
    if (!output || capacity < output_size) return -2;
    for (std::size_t i = 0; i < 16 * boundaries; ++i) {
        const auto value = static_cast<std::uint32_t>(staged[i]);
        output[4 * i] = static_cast<std::uint8_t>(value);
        output[4 * i + 1] = static_cast<std::uint8_t>(value >> 8);
        output[4 * i + 2] = static_cast<std::uint8_t>(value >> 16);
        output[4 * i + 3] = static_cast<std::uint8_t>(value >> 24);
    }
    return static_cast<std::int64_t>(output_size);
}
