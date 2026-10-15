#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 1024; }

static std::int64_t lower_ascii(std::int64_t value) noexcept {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

extern "C" std::int64_t check_palindrome2(const std::int64_t* values, std::size_t length,
                                           std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -1;

    std::size_t start = 0;
    std::size_t end = length;
    while (start < end && values[start] == 32) ++start;
    while (end > start && values[end - 1] == 32) --end;
    const std::size_t normalized_length = end - start;
    if (normalized_length == 0 || (normalized_length == 1 && values[start] == '0')) return -1;

    bool palindrome = true;
    for (std::size_t left = 0; left < normalized_length / 2; ++left) {
        const std::size_t right = normalized_length - left - 1;
        if (lower_ascii(values[start + left]) != lower_ascii(values[start + right])) palindrome = false;
    }
    const char* suffix = palindrome ? " - a palindrome string.\n" : " - not a palindrome string.\n";
    const std::size_t suffix_length = palindrome ? 24 : 28;
    if (output == nullptr || output_capacity < normalized_length + suffix_length) return -2;
    for (std::size_t i = 0; i < normalized_length; ++i)
        output[i] = static_cast<std::uint8_t>(lower_ascii(values[start + i]));
    for (std::size_t i = 0; i < suffix_length; ++i)
        output[normalized_length + i] = static_cast<std::uint8_t>(suffix[i]);
    return static_cast<std::int64_t>(normalized_length + suffix_length);
}
