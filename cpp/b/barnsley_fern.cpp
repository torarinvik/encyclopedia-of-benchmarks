/* Portable fixed-point port of TheAlgorithms/Python's Barnsley fern maps. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t q12_offset = INT64_C(10000000000);
constexpr std::int64_t q6_divisor = INT64_C(1000000);

std::int64_t round_div_even(std::int64_t numerator, std::int64_t denominator) {
    const bool negative = numerator < 0;
    const auto magnitude = static_cast<std::uint64_t>(negative ? -numerator : numerator);
    const auto divisor = static_cast<std::uint64_t>(denominator);
    auto quotient = magnitude / divisor;
    const auto remainder = magnitude % divisor;
    if (remainder * 2 > divisor || (remainder * 2 == divisor && (quotient & 1u))) ++quotient;
    return negative ? -static_cast<std::int64_t>(quotient) : static_cast<std::int64_t>(quotient);
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t barnsley_fern(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1) return -1;
    const auto iteration_value = input[0];
    if (iteration_value < 1 || iteration_value > 4096 || length != static_cast<std::size_t>(iteration_value))
        return -1;
    const auto iterations = static_cast<std::size_t>(iteration_value);
    for (std::size_t step = 1; step < iterations; ++step)
        if (input[step] < 0 || input[step] >= 10000) return -1;
    const auto output_length = iterations * 16;
    if (output == nullptr || capacity < output_length) return -2;

    std::int64_t x = 0, y = 0;
    put_i64_le(output, 0, 0);
    put_i64_le(output, 8, 0);
    for (std::size_t step = 1; step < iterations; ++step) {
        const auto sample = input[step];
        std::int64_t a = 0, b = 0, c = 0, d = 0, e = 0, f = 0;
        if (sample < 100) d = 16;
        else if (sample < 8600) { a = 85; b = 4; c = -4; d = 85; f = 160; }
        else if (sample < 9300) { a = 20; b = -26; c = 23; d = 22; f = 160; }
        else { a = -15; b = 28; c = 26; d = 24; f = 44; }
        const auto next_x = round_div_even(a * x + b * y, 100) + e * q12_offset;
        const auto next_y = round_div_even(c * x + d * y, 100) + f * q12_offset;
        x = next_x;
        y = next_y;
        put_i64_le(output, step * 16, round_div_even(x, q6_divisor));
        put_i64_le(output, step * 16 + 8, round_div_even(y, q6_divisor));
    }
    return static_cast<std::int64_t>(output_length);
}
