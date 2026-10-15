// Count transitions from ASCII space to a non-space byte.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t count_segments(const std::int64_t *input,
    std::size_t length) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    std::int64_t count = 0;
    bool previous_was_space = true;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = input[index];
        if (value < 1 || value > 127) return -1;
        if (value != 32 && previous_was_space) ++count;
        previous_was_space = value == 32;
    }
    return count;
}
