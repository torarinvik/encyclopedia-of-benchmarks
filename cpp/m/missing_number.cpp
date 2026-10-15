// Return the absent value from the inclusive range 0 through array length.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
}

extern "C" std::int64_t missing_number(const std::int64_t *values,
                                       std::size_t length) noexcept {
    if (length > max_values || (length != 0 && values == nullptr)) return -1;
    bool seen[max_values + 1]{};
    std::int64_t actual_sum = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = values[i];
        if (value < 0 || static_cast<std::uint64_t>(value) > length || seen[value]) return -1;
        seen[value] = true;
        actual_sum += value;
    }
    const auto n = static_cast<std::int64_t>(length);
    return n * (n + 1) / 2 - actual_sum;
}
