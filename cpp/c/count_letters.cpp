#include <cstddef>
#include <cstdint>

namespace {
std::int64_t lowercase_ascii_letter(std::int64_t value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}
}

extern "C" std::int64_t count_letters(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || input[1] < 0 || input[1] > 256) return -1;
    const auto text_length = static_cast<std::size_t>(input[1]);
    if (length != text_length + 2) return -1;
    const auto query = lowercase_ascii_letter(input[0]);
    if (query < 'a' || query > 'z') return -1;
    std::int64_t count = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto value = input[index + 2];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return -1;
        if (lowercase_ascii_letter(value) == query) ++count;
    }
    return count;
}
