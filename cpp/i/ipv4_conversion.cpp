#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::int64_t invalid_result = std::numeric_limits<std::int64_t>::min();
}

extern "C" std::int64_t ipv4_conversion(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 4) return invalid_result;
    std::int64_t address = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        const auto octet = input[index];
        if (octet < 0 || octet > 255) return invalid_result;
        address = address * 256 + octet;
    }
    return address;
}
