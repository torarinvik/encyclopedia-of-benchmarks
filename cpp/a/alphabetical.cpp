// Check whether an ASCII letter string is case-insensitively sorted.
#include <cstddef>
#include <cstdint>

namespace {
bool is_ascii_letter(std::int64_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

std::int64_t lowercase_ascii(std::int64_t value) noexcept {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}
}

extern "C" std::int64_t alphabetical(const std::int64_t *values, std::size_t length) noexcept {
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return -1;

    if (length == 0) return 0;
    std::int64_t previous = -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (!is_ascii_letter(values[index])) return 0;
        const auto current = lowercase_ascii(values[index]);
        if (current < previous) return 0;
        previous = current;
    }
    return 1;
}
