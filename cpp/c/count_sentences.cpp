#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 4096;

bool is_trim_byte(std::uint8_t value) noexcept {
    return value == 0 || value == 9 || value == 10 || value == 11 || value == 13 || value == 32;
}
bool is_regex_space(std::uint8_t value) noexcept {
    return (value >= 9 && value <= 13) || value == 32;
}
bool is_word_byte(std::uint8_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9') || value == '_';
}
bool is_terminator(std::uint8_t value) noexcept {
    return value == '.' || value == '!' || value == '?';
}
bool is_eligible_predecessor(std::uint8_t value) noexcept {
    return !is_regex_space(value) && value != '|' && value != '^' && value != '.';
}
}

extern "C" std::int64_t count_sentences(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_text_length + 1 ||
        input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length) ||
        length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    std::uint8_t text[max_text_length]{};
    for (std::size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
        text[index] = static_cast<std::uint8_t>(input[index + 1]);
    }

    std::size_t begin = 0, end = text_length;
    while (begin < end && is_trim_byte(text[begin])) ++begin;
    while (end > begin && is_trim_byte(text[end - 1])) --end;
    std::size_t cursor = begin;
    std::int64_t count = 0;
    while (cursor + 1 < end) {
        bool found = false;
        for (std::size_t index = cursor; index + 1 < end; ++index) {
            if (is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
                (index + 2 == end || !is_word_byte(text[index + 2]))) {
                ++count;
                cursor = index + 2;
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return count;
}
