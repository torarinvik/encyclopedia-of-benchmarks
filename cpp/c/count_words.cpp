#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 4096;
bool is_trim_character(std::int64_t value) { return value <= 32; }
bool is_regex_whitespace(std::int64_t value)
{
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}
}

// Count tokens after Java String.trim() and split("\\s+").
extern "C" std::int64_t count_words(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > MAX_LENGTH || (length > 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    if (length == 0) return 0;
    std::size_t start = 0;
    std::size_t end = length;
    while (start < end && is_trim_character(values[start])) ++start;
    while (end > start && is_trim_character(values[end - 1])) --end;
    if (start == end) return 1;
    std::int64_t count = 0;
    bool in_word = false;
    for (std::size_t i = start; i < end; ++i) {
        if (is_regex_whitespace(values[i])) in_word = false;
        else if (!in_word) { ++count; in_word = true; }
    }
    return count;
}
