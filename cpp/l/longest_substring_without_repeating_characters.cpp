// Return the longest printable-ASCII substring with no repeated byte.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 1024;
constexpr std::size_t alphabet_size = 95;
constexpr std::int64_t invalid_result = -2;
}

extern "C" std::int64_t longest_substring_without_repeating_characters(
    const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return invalid_result;
    std::int64_t last_seen[alphabet_size];
    for (std::size_t slot = 0; slot < alphabet_size; ++slot) last_seen[slot] = -1;
    std::size_t window_start = 0;
    std::size_t longest = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 32 || value > 126) return invalid_result;
        const std::size_t slot = static_cast<std::size_t>(value - 32);
        if (last_seen[slot] >= 0 && static_cast<std::size_t>(last_seen[slot]) >= window_start)
            window_start = static_cast<std::size_t>(last_seen[slot]) + 1;
        last_seen[slot] = static_cast<std::int64_t>(index);
        const std::size_t current = index - window_start + 1;
        if (current > longest) longest = current;
    }
    return static_cast<std::int64_t>(longest);
}
