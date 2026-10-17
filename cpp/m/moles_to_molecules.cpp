#include <cstddef>
#include <cstdint>
#include <cstring>

static double parse_scientific_four(double value) {
    if (value == 0.0) return 0.0;
    int decimal_exponent = 0;
    double normalized = value;
    while (normalized >= 10.0) { normalized /= 10.0; ++decimal_exponent; }
    while (normalized < 1.0) { normalized *= 10.0; --decimal_exponent; }

    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const std::uint64_t fraction = bits & ((std::uint64_t{1} << 52) - 1);
    const int exponent_bits = static_cast<int>((bits >> 52) & 0x7ff);
    const std::uint64_t significand = (std::uint64_t{1} << 52) | fraction;
    const int binary_exponent = exponent_bits - 1023 - 52;
    const int decimal_shift = decimal_exponent - 4;
    std::uint64_t denominator = 1;
    for (int index = 0; index < decimal_shift; ++index) denominator *= 5;
    const int binary_shift = binary_exponent - decimal_shift;
    std::uint64_t numerator = significand;
    if (binary_shift >= 0) numerator <<= binary_shift;
    else denominator <<= -binary_shift;
    std::uint64_t rounded = numerator / denominator;
    const std::uint64_t remainder = numerator % denominator;
    const std::uint64_t twice_remainder = remainder * 2;
    if (twice_remainder > denominator || (twice_remainder == denominator && (rounded & 1) != 0)) ++rounded;
    double decimal_scale = 1.0;
    for (int index = 0; index < decimal_shift; ++index) decimal_scale *= 10.0;
    return static_cast<double>(rounded) * decimal_scale;
}

extern "C" double moles_to_molecules(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 1 || input[0] < 0 || input[0] > 2000000) return -1.0e300;
    const double moles = static_cast<double>(input[0]) / 1000000.0;
    const double molecules = moles * 6.022e23;
    return parse_scientific_four(molecules);
}
