#include <cstddef>
#include <cstdint>

static int64_t gcd_positive(int64_t left, int64_t right) {
    while (right != 0) { const int64_t remainder = left % right; left = right; right = remainder; }
    return left;
}

extern "C" int64_t continued_fraction(const int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 2) return -1;
    int64_t numerator = input[0], denominator = input[1];
    if (numerator < -1000000 || numerator > 1000000 || denominator < -1000000 ||
        denominator > 1000000 || denominator == 0) return -1;
    const int64_t divisor = gcd_positive(numerator < 0 ? -numerator : numerator,
                                         denominator < 0 ? -denominator : denominator);
    numerator /= divisor;
    denominator /= divisor;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    int64_t coefficients[32];
    std::size_t count = 0;
    while (true) {
        int64_t quotient = numerator / denominator;
        int64_t remainder = numerator % denominator;
        if (remainder < 0) { --quotient; remainder += denominator; }
        if (count == 32) return -1;
        coefficients[count++] = quotient;
        if (remainder == 0) break;
        numerator = denominator;
        denominator = remainder;
    }
    const std::size_t bytes = count * 8;
    if (bytes > capacity || output == nullptr) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint64_t bits = static_cast<std::uint64_t>(coefficients[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<int64_t>(bytes);
}
