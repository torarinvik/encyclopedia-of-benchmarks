// Check whether the bounded ASCII input is entirely lowercase letters.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t check_flat_case(const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (value < 32 || value > 126) return -2;
    }
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 'a' || values[i] > 'z') return 0;
    return 1;
}
