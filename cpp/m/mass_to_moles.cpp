#include <cstddef>
#include <cstdint>
#include <cstring>

static double round_binary64_to_hundredth(double value) {
    if (value == 0.0) return 0.0;
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const std::uint64_t fraction = bits & ((std::uint64_t{1} << 52) - 1);
    const unsigned exponent_bits = static_cast<unsigned>((bits >> 52) & 0x7ff);
    const std::uint64_t significand = (std::uint64_t{1} << 52) | fraction;
    const int binary_exponent = static_cast<int>(exponent_bits) - 1023 - 52;
    const unsigned shift = static_cast<unsigned>(-binary_exponent);
    const std::uint64_t scaled_significand = significand * 100;
    const std::uint64_t denominator = std::uint64_t{1} << shift;
    std::uint64_t hundredths = scaled_significand >> shift;
    const std::uint64_t remainder = scaled_significand & (denominator - 1);
    const std::uint64_t halfway = denominator >> 1;
    if (remainder > halfway || (remainder == halfway && (hundredths & 1) != 0)) ++hundredths;
    return static_cast<double>(hundredths) / 100.0;
}

extern "C" double mass_to_moles(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 2 || input[0] < 0 || input[0] > 1000 ||
        input[1] < 1 || input[1] > 1000) return -1.0e300;
    const double quotient = static_cast<double>(input[0]) / static_cast<double>(input[1]);
    return round_binary64_to_hundredth(quotient);
}
