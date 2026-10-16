/* Return the greedy Egyptian-fraction unit denominators as little-endian i32s. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t egyptian_fraction(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length != 2) return -1;
    std::int64_t numerator = input[0], denominator = input[1];
    if (numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator) return -1;

    std::uint32_t terms[10];
    std::size_t count = 0;
    while (numerator != 0) {
        std::int64_t unit_denominator = denominator / numerator;
        if (denominator % numerator != 0) ++unit_denominator;
        terms[count++] = static_cast<std::uint32_t>(unit_denominator);
        numerator = numerator * unit_denominator - denominator;
        denominator = denominator * unit_denominator;
    }
    const std::size_t required = count * 4;
    if (output_capacity < required || (required > 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const std::uint32_t value = terms[index];
        for (std::size_t byte = 0; byte < 4; ++byte) output[index * 4 + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
