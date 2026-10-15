// Count ASCII vowels in a bounded string represented by byte values.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
constexpr std::int64_t invalid_result = -2;
}

extern "C" std::int64_t count_vowels(const std::int64_t *values, std::size_t length) noexcept {
    if (length == 0 || length > max_length || values == nullptr) return invalid_result;
    if (length == 1 && values[0] == '0') return invalid_result;
    std::int64_t count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (value < 0 || value > 127 || value == ',') return invalid_result;
        if (value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u' ||
            value == 'A' || value == 'E' || value == 'I' || value == 'O' || value == 'U') ++count;
    }
    return count;
}
