#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;

std::int64_t signed_int32(std::uint32_t bits) {
    return bits <= INT32_MAX ? static_cast<std::int64_t>(bits)
                             : static_cast<std::int64_t>(bits) - INT64_C(4294967296);
}
}

extern "C" std::int64_t parse_integer(const std::int64_t *bytes, std::size_t length) noexcept {
    if (bytes == nullptr || length == 0 || length > 64) return invalid_result;
    for (std::size_t i = 0; i < length; ++i) if (bytes[i] < 0 || bytes[i] > 127) return invalid_result;
    const bool negative = bytes[0] == '-';
    std::size_t index = (bytes[0] == '-' || bytes[0] == '+') ? 1 : 0;
    std::uint32_t number = 0;
    for (; index < length; ++index) {
        if (bytes[index] < '0' || bytes[index] > '9') return invalid_result;
        number = number * UINT32_C(10) + static_cast<std::uint32_t>(bytes[index] - '0');
    }
    if (negative) number = UINT32_C(0) - number;
    return signed_int32(number);
}
