#include <array>
#include <cstddef>
#include <cstdint>

namespace {
void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}

extern "C" std::int64_t decimal_expansion(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity)
{
    if (values == nullptr || length != 3) return -1;
    const auto numerator = values[0];
    const auto denominator = values[1];
    const auto base = values[2];
    if (numerator < 0 || denominator < 1 || denominator > 256 ||
        numerator > denominator || base < 2 || base > 10) return -1;

    std::array<std::uint8_t, 255> digits{};
    std::array<std::int64_t, 256> first_seen;
    first_seen.fill(-1);
    std::size_t digit_count = 0;
    std::int64_t cycle_start = -1;
    auto remainder = numerator;
    while (remainder != 0 && numerator != denominator) {
        const auto remainder_index = static_cast<std::size_t>(remainder);
        if (first_seen[remainder_index] >= 0) {
            cycle_start = first_seen[remainder_index];
            break;
        }
        first_seen[remainder_index] = static_cast<std::int64_t>(digit_count);
        const auto scaled = remainder * base;
        digits[digit_count++] = static_cast<std::uint8_t>(scaled / denominator);
        remainder = scaled % denominator;
    }

    const auto required = std::size_t{24} + digit_count;
    if (output == nullptr || capacity < required) return -2;
    write_i64_le(output, 0, numerator == denominator ? 1 : 0);
    write_i64_le(output, 8, static_cast<std::int64_t>(digit_count));
    write_i64_le(output, 16, cycle_start);
    for (std::size_t index = 0; index < digit_count; ++index) output[24 + index] = digits[index];
    return static_cast<std::int64_t>(required);
}
