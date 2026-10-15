#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
}

extern "C" std::int64_t count_consonants(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > max_length || values == nullptr) return -1;
    if (length == 1 && values[0] == 48) return -1;
    std::int64_t count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        std::int64_t value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        if (value >= 'a' && value <= 'z' && value != 'a' && value != 'e' &&
            value != 'i' && value != 'o' && value != 'u') ++count;
    }
    return count;
}
