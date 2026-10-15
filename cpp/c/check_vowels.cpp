#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MAX_LENGTH = 4096; }

// Return whether any lowercase ASCII vowel appears in the input.
extern "C" std::int64_t check_vowels(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > MAX_LENGTH || (length > 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < 97 || values[i] > 122) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = values[i];
        if (value == 97 || value == 101 || value == 105 || value == 111 || value == 117) return 1;
    }
    return 0;
}
