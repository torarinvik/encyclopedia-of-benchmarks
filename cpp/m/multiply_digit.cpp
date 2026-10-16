// Multiply two bounded signed operands; the bounds guarantee an i64 result.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = INT64_MIN; }

extern "C" std::int64_t multiply_digit(const std::int64_t *values,
    std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const auto first = values[0];
    const auto second = values[1];
    if (first < -1'000'000'000LL || first > 1'000'000'000LL ||
        second < -1'000'000'000LL || second > 1'000'000'000LL) return invalid_result;
    return first * second;
}
