#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_word_length = 16, max_candidates = 16;
bool letter(std::int64_t value) noexcept { return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'); }
int lower_index(std::int64_t value) noexcept { return value >= 'A' && value <= 'Z' ? static_cast<int>(value - 'A') : static_cast<int>(value - 'a'); }
bool put_byte(std::uint8_t *output, std::size_t capacity, std::size_t &length, std::uint8_t value) noexcept {
    if (length >= capacity) return false;
    output[length++] = value; return true;
}
}

extern "C" std::int64_t detect_anagrams(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 2 || input[0] < 0 || input[0] > max_word_length) return -1;
    const auto subject_length = static_cast<std::size_t>(input[0]);
    std::size_t offset = 1 + subject_length;
    if (offset >= length) return -1;
    for (std::size_t i = 0; i < subject_length; ++i) if (!letter(input[1 + i])) return -1;
    if (input[offset] < 0 || input[offset] > max_candidates) return -1;
    const auto candidate_count = static_cast<std::size_t>(input[offset++]);
    int subject_counts[26] = {};
    for (std::size_t i = 0; i < subject_length; ++i) ++subject_counts[lower_index(input[1 + i])];
    if (!output) return -2;
    std::size_t output_length = 0;
    std::int64_t matches = 0;
    for (std::size_t candidate = 0; candidate < candidate_count; ++candidate) {
        if (offset >= length || input[offset] < 0 || input[offset] > max_word_length) return -1;
        const auto word_length = static_cast<std::size_t>(input[offset++]);
        if (offset + word_length > length) return -1;
        int counts[26];
        for (std::size_t i = 0; i < 26; ++i) counts[i] = subject_counts[i];
        bool identical = word_length == subject_length;
        for (std::size_t i = 0; i < word_length; ++i) {
            if (!letter(input[offset + i])) return -1;
            --counts[lower_index(input[offset + i])];
            if (identical && lower_index(input[offset + i]) != lower_index(input[1 + i])) identical = false;
        }
        bool same_counts = word_length == subject_length;
        for (int count : counts) if (count != 0) same_counts = false;
        if (same_counts && !identical) {
            for (std::size_t i = 0; i < word_length; ++i) if (!put_byte(output, capacity, output_length, static_cast<std::uint8_t>(input[offset + i]))) return -2;
            if (!put_byte(output, capacity, output_length, '\n')) return -2;
            ++matches;
        }
        offset += word_length;
    }
    if (offset != length) return -1;
    if (!put_byte(output, capacity, output_length, 0)) return -2;
    return matches;
}
