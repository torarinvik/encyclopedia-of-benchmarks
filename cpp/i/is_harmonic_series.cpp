// Exact-equality reciprocal progression predicate for IEEE-754 inputs.
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_VALUES = 32;
constexpr double INVALID_RESULT = -1.0e300;

double decode_binary64(std::int64_t signed_bits) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(signed_bits);
    double value;
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}
}

extern "C" double is_harmonic_series(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > MAX_VALUES + 1) return INVALID_RESULT;
    const auto count = values[0];
    if (count < 1 || count > static_cast<std::int64_t>(MAX_VALUES) ||
        length != static_cast<std::size_t>(count) + 1) return INVALID_RESULT;

    double reciprocals[MAX_VALUES];
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const double value = decode_binary64(values[i + 1]);
        if (value == 0.0) return INVALID_RESULT;
        reciprocals[i] = 1.0 / value;
    }
    if (count == 1) return 1.0;
    const double common_difference = reciprocals[1] - reciprocals[0];
    for (std::size_t i = 2; i < static_cast<std::size_t>(count); ++i)
        if (reciprocals[i] - reciprocals[i - 1] != common_difference) return 0.0;
    return 1.0;
}
