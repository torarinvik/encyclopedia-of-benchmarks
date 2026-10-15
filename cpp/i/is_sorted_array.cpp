#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 100000;
constexpr std::int64_t max_safe_integer = INT64_C(9007199254740991);
}

extern "C" std::int64_t is_sorted_array(const std::int64_t* values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < -max_safe_integer || values[i] > max_safe_integer) return -1;
    for (std::size_t i = 0; i + 1 < length; ++i)
        if (values[i] >= values[i + 1]) return 0;
    return 1;
}
