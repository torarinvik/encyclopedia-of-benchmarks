#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TERMS = 64;
constexpr std::size_t MAX_WORDS = 66;
constexpr std::int64_t VALUE_LIMIT = 1000000;

std::uint64_t aitken_gcd(std::uint64_t left, std::uint64_t right)
{
    while (right != 0) {
        const std::uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

void aitken_store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t aitken_delta_squared_sequence_transform(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_WORDS) return -1;
    const auto n_value = values[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(MAX_TERMS) ||
        length != static_cast<std::size_t>(n_value) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    for (std::size_t index = 0; index < n; ++index)
        if (values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT) return -1;
    const auto output_length = 16 * (n - 2);
    if (output == nullptr || output_capacity < output_length) return -2;

    for (std::size_t index = 0; index + 2 < n; ++index) {
        const auto first = values[index + 1];
        const auto middle = values[index + 2];
        const auto last = values[index + 3];
        auto numerator = first * last - middle * middle;
        auto denominator = first - 2 * middle + last;
        if (denominator == 0) {
            if (first == middle && middle == last) {
                numerator = first;
                denominator = 1;
            } else {
                numerator = 0;
            }
        } else {
            if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
            const auto magnitude = numerator < 0 ? static_cast<std::uint64_t>(-numerator)
                                                  : static_cast<std::uint64_t>(numerator);
            const auto divisor = aitken_gcd(magnitude, static_cast<std::uint64_t>(denominator));
            numerator /= static_cast<std::int64_t>(divisor);
            denominator /= static_cast<std::int64_t>(divisor);
        }
        const auto offset = index * 16;
        aitken_store_i64(output, offset, numerator);
        aitken_store_i64(output, offset + 8, denominator);
    }
    return static_cast<std::int64_t>(output_length);
}
