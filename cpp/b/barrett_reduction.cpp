#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t radix = INT64_C(4294967296);
constexpr std::int64_t max_modulus = 65535;
constexpr std::size_t max_values = 12;
constexpr std::size_t max_length = 15;
}

extern "C" std::int64_t barrett_reduction(const std::int64_t *input,
                                           std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    const auto modulus = input[0];
    const auto count_value = input[1];
    if (modulus < 2 || modulus > max_modulus || count_value < 0 || count_value > static_cast<std::int64_t>(max_values)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + count) return -1;
    const auto square_bound = modulus * modulus;
    for (std::size_t i = 0; i < count; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= square_bound) return -1;

    const auto reciprocal = radix / modulus;
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[2 + i];
        const auto quotient = (value * reciprocal) / radix;
        auto remainder = value - quotient * modulus;
        if (remainder >= modulus) remainder -= modulus;
        checksum += static_cast<std::int64_t>(i + 1) * (remainder + 1);
    }
    return checksum;
}
