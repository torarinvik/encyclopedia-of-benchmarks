#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (8 * byte)) & 0xffu);
    }
}
}

extern "C" std::int64_t farey_approximation(const std::int64_t* values, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t decimal_millionths = values[0];
    const std::int64_t repeat = values[1];
    if (decimal_millionths < 1 || decimal_millionths > 999999 || repeat < 1 || repeat > 20) return -1;
    if (output == nullptr || capacity < 16) return -2;

    const double decimal = static_cast<double>(decimal_millionths) / 1000000.0;
    std::int64_t a = 0, b = 1, c = 1, d = 1;
    std::int64_t numerator = 0, denominator = 0;
    for (std::int64_t i = 0; i < repeat; ++i) {
        numerator = a + c;
        denominator = b + d;
        if (decimal > static_cast<double>(numerator) / static_cast<double>(denominator)) {
            a = numerator;
            b = denominator;
        } else {
            c = numerator;
            d = denominator;
        }
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
