#include <cstddef>
#include <cstdint>

namespace {
std::int64_t lower_ascii(std::int64_t value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}
}

extern "C" std::int64_t percentage_of_letters(const std::int64_t *values, std::size_t length) {
    if (length < 2 || length > 4097 || values == nullptr) return -1;
    const auto target = lower_ascii(values[0]);
    if (target < 'a' || target > 'z') return -1;
    const auto text_length = length - 1;
    std::size_t matches = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto value = values[index + 1];
        if (value < 0 || value > 127) return -1;
        if (lower_ascii(value) == target) ++matches;
    }
    return static_cast<std::int64_t>((100 * matches) / text_length);
}
