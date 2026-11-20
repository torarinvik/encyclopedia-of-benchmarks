#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TERMS = 16;
constexpr std::size_t MAX_WORDS = 18;
constexpr std::int64_t VALUE_LIMIT = 1000000;
constexpr std::size_t OUTPUT_BYTES = 16;

std::uint64_t euler_gcd(std::uint64_t left, std::uint64_t right)
{
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

void euler_store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t euler_alternating_series_transform(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > MAX_WORDS) return -1;
    const auto n_value = values[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_TERMS) ||
        length != static_cast<std::size_t>(n_value) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    for (std::size_t index = 0; index < n; ++index)
        if (values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT)
            return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;

    std::int64_t numerator = 0;
    for (std::size_t order = 0; order < n; ++order) {
        std::int64_t difference = 0;
        std::int64_t coefficient = 1;
        for (std::size_t index = 0; index <= order; ++index) {
            const auto term = values[order - index + 1];
            if (index % 2 == 0) difference += coefficient * term;
            else difference -= coefficient * term;
            if (index < order)
                coefficient = coefficient * static_cast<std::int64_t>(order - index) /
                              static_cast<std::int64_t>(index + 1);
        }
        const auto weight = std::int64_t{1} << (n - order - 1);
        const auto weighted = difference * weight;
        if (order % 2 == 0) numerator += weighted;
        else numerator -= weighted;
    }

    auto denominator = std::int64_t{1} << n;
    const auto magnitude = numerator < 0
        ? static_cast<std::uint64_t>(-numerator) : static_cast<std::uint64_t>(numerator);
    const auto divisor = euler_gcd(magnitude, static_cast<std::uint64_t>(denominator));
    numerator /= static_cast<std::int64_t>(divisor);
    denominator /= static_cast<std::int64_t>(divisor);
    euler_store_i64(output, 0, numerator);
    euler_store_i64(output, 8, denominator);
    return static_cast<std::int64_t>(OUTPUT_BYTES);
}
