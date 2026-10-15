// Check the bounded ASCII camel-case predicate.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t check_camel_case(const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -2;
    if (length == 0) return 0;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;
    if (values[0] < 'a' || values[0] > 'z') return 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return 0;
    }
    return 1;
}
