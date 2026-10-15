// Count Julia-regex words after ASCII lowercasing.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxLength = 1000;
struct WordEntry { std::size_t start, length, count; };

std::uint8_t lower_byte(const std::int64_t *input, std::size_t index) noexcept {
    const auto byte = static_cast<std::uint8_t>(input[index]);
    return byte >= 'A' && byte <= 'Z' ? static_cast<std::uint8_t>(byte + ('a' - 'A')) : byte;
}
bool is_word_byte(std::uint8_t byte) noexcept {
    return (byte >= 'a' && byte <= 'z') || (byte >= '0' && byte <= '9') || byte == '_';
}
int compare_word(const std::int64_t *input, std::size_t start, std::size_t length,
                 const WordEntry &entry) noexcept {
    const auto shared = length < entry.length ? length : entry.length;
    for (std::size_t i = 0; i < shared; ++i) {
        const auto left = lower_byte(input, start + i), right = lower_byte(input, entry.start + i);
        if (left != right) return left < right ? -1 : 1;
    }
    return length < entry.length ? -1 : length > entry.length ? 1 : 0;
}
std::size_t write_count(std::uint8_t *output, std::size_t position, std::size_t count) noexcept {
    std::uint8_t digits[4]; std::size_t digit_count = 0;
    do { digits[digit_count++] = static_cast<std::uint8_t>('0' + count % 10); count /= 10; } while (count != 0);
    output[position++] = '=';
    while (digit_count != 0) output[position++] = digits[--digit_count];
    output[position++] = '\n';
    return position;
}
}

extern "C" std::int64_t word_count_julia(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > MaxLength || (length != 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return -1;
    WordEntry entries[MaxLength]; std::size_t unique_count = 0, index = 0;
    while (index < length) {
        if (!is_word_byte(lower_byte(input, index))) { ++index; continue; }
        const auto start = index;
        while (index < length && is_word_byte(lower_byte(input, index))) ++index;
        auto token_length = index - start;
        if (index + 1 < length && input[index] == '\'' && is_word_byte(lower_byte(input, index + 1))) {
            token_length += 2; index += 2;
        }
        std::size_t position = 0;
        while (position < unique_count && compare_word(input, start, token_length, entries[position]) > 0) ++position;
        if (position < unique_count && compare_word(input, start, token_length, entries[position]) == 0) {
            ++entries[position].count;
        } else {
            for (auto move = unique_count; move > position; --move) entries[move] = entries[move - 1];
            entries[position] = {start, token_length, 1}; ++unique_count;
        }
    }
    std::size_t required = 0;
    for (std::size_t item = 0; item < unique_count; ++item) {
        std::size_t digits = 1;
        for (auto value = entries[item].count; value >= 10; value /= 10) ++digits;
        required += entries[item].length + digits + 2;
    }
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t item = 0; item < unique_count; ++item) {
        for (std::size_t offset = 0; offset < entries[item].length; ++offset)
            output[written++] = lower_byte(input, entries[item].start + offset);
        written = write_count(output, written, entries[item].count);
    }
    return static_cast<std::int64_t>(written);
}
