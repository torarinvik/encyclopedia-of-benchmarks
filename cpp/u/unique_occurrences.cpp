#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t unique_occurrences(const int64_t *values, size_t length) {
    if (length > 1000 || (length != 0 && values == nullptr)) return -1;
    std::array<int64_t, 2001> counts{};
    std::array<bool, 1001> seen_frequencies{};
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < -1000 || value > 1000) return -1;
        ++counts[static_cast<size_t>(value + 1000)];
    }
    for (const int64_t frequency : counts) {
        if (frequency == 0) continue;
        if (seen_frequencies[static_cast<size_t>(frequency)]) return 0;
        seen_frequencies[static_cast<size_t>(frequency)] = true;
    }
    return 1;
}
