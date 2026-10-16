#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 4096;
std::uint8_t lower_ascii(std::uint8_t c) { return c >= 'A' && c <= 'Z' ? static_cast<std::uint8_t>(c + 32) : c; }
bool vowel(std::uint8_t c) { return c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u'; }
}
extern "C" std::int64_t remove_vowels(const std::int64_t *values, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > max_input_length || length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    std::size_t result = 0;
    for (std::size_t i = 0; i < n; ++i) { if (values[i+1] < 0 || values[i+1] > 127) return -1; if (!vowel(lower_ascii(static_cast<std::uint8_t>(values[i+1])))) ++result; }
    if (result > capacity || (result > 0 && output == nullptr)) return -2;
    std::size_t j = 0;
    for (std::size_t i = 0; i < n; ++i) { auto c = lower_ascii(static_cast<std::uint8_t>(values[i+1])); if (!vowel(c)) output[j++] = c; }
    return static_cast<std::int64_t>(j);
}
