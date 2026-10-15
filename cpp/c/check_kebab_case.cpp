#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

static bool is_ascii_word(std::int64_t value) noexcept {
    return (value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
           (value >= '0' && value <= '9');
}

extern "C" std::int64_t check_kebab_case(const std::int64_t* values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] == '_') return 0;
    for (std::size_t i = 1; i + 1 < length; ++i)
        if (values[i] == '-' && is_ascii_word(values[i - 1]) && is_ascii_word(values[i + 1])) return 1;
    return 0;
}
