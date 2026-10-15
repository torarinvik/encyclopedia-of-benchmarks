#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ENCODED_VALUE = 999'999'999;
}

extern "C" std::int64_t anyto_any(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 3) return -1;
    auto encoded = input[0];
    const auto source_base = input[1];
    const auto destination_base = input[2];
    if (encoded < 0 || encoded > MAX_ENCODED_VALUE || source_base < 2 || source_base > 10 ||
        destination_base < 2 || destination_base > 10) return -1;

    std::int64_t decimal_value = 0;
    std::int64_t source_multiplier = 1;
    while (encoded > 0) {
        const auto digit = encoded % 10;
        if (digit >= source_base) return -1;
        decimal_value += digit * source_multiplier;
        source_multiplier *= source_base;
        encoded /= 10;
    }

    std::int64_t result = 0;
    std::int64_t destination_multiplier = 1;
    while (decimal_value > 0) {
        const auto digit = decimal_value % destination_base;
        result += digit * destination_multiplier;
        decimal_value /= destination_base;
        if (decimal_value > 0) {
            if (destination_multiplier > MAX_ENCODED_VALUE / 10) return -1;
            destination_multiplier *= 10;
        }
    }
    return result;
}
