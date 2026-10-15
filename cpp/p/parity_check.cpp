#include <cstdint>
#include <limits>

extern "C" std::int64_t parity_check(std::int64_t value) noexcept {
    if (value < std::numeric_limits<std::int32_t>::min() ||
        value > std::numeric_limits<std::int32_t>::max()) return -1;
    auto number = static_cast<std::int32_t>(value);
    std::int32_t parity = 0;
    while (number > 0) {
        parity ^= number & 1;
        number >>= 1;
    }
    return parity == 0 ? 1 : 0;
}
