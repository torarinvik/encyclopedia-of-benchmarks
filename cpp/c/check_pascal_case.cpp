// Check the bounded ASCII Pascal-case predicate.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t check_pascal_case(const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;
    if (length == 0 || values[0] < 'A' || values[0] > 'Z') return 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return 0;
    }
    return 1;
}
