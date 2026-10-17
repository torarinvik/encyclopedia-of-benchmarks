#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_keyword_length = 64;
constexpr std::size_t max_plaintext_length = 512;
constexpr std::size_t max_input_length = 2 + max_keyword_length + max_plaintext_length;
} // namespace

extern "C" std::int64_t mixed_keyword_cypher(const std::int64_t* input,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;

    const auto raw_keyword_length = input[0];
    if (raw_keyword_length < 1 || raw_keyword_length > static_cast<std::int64_t>(max_keyword_length))
        return -1;
    const auto keyword_length = static_cast<std::size_t>(raw_keyword_length);
    const auto plaintext_length_index = 1 + keyword_length;
    if (plaintext_length_index >= length) return -1;

    const auto raw_plaintext_length = input[plaintext_length_index];
    if (raw_plaintext_length < 0 || raw_plaintext_length > static_cast<std::int64_t>(max_plaintext_length))
        return -1;
    const auto plaintext_length = static_cast<std::size_t>(raw_plaintext_length);
    if (length != plaintext_length_index + 1 + plaintext_length) return -1;

    std::array<std::uint8_t, 26> unique_letters{};
    std::array<bool, 26> seen{};
    std::size_t unique_count = 0;
    for (std::size_t index = 0; index < keyword_length; ++index) {
        const auto raw = input[1 + index];
        if (raw < 0 || raw > 127) return -1;
        auto letter = static_cast<int>(raw);
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z') {
            const auto alphabet_index = static_cast<std::size_t>(letter - 'A');
            if (!seen[alphabet_index]) {
                seen[alphabet_index] = true;
                unique_letters[unique_count++] = static_cast<std::uint8_t>(letter);
            }
        }
    }
    if (unique_count == 0) return -1;

    for (std::size_t index = 0; index < plaintext_length; ++index) {
        const auto raw = input[plaintext_length_index + 1 + index];
        if (raw < 0 || raw > 127) return -1;
    }

    std::array<std::uint8_t, 26> shifted{};
    for (std::size_t index = 0; index < unique_count; ++index)
        shifted[index] = unique_letters[index];
    auto shifted_count = unique_count;
    for (std::size_t index = 0; index < 26; ++index) {
        if (!seen[index]) shifted[shifted_count++] = static_cast<std::uint8_t>('A' + index);
    }

    std::array<std::uint8_t, 26> mapping{};
    std::size_t alphabet_index = 0;
    for (std::size_t column = 0; column < unique_count; ++column) {
        for (std::size_t row_start = 0; row_start < 26; row_start += unique_count) {
            const auto shifted_index = row_start + column;
            if (shifted_index >= 26) break;
            mapping[alphabet_index++] = shifted[shifted_index];
        }
    }

    std::array<std::uint8_t, max_plaintext_length> buffer{};
    for (std::size_t index = 0; index < plaintext_length; ++index) {
        auto letter = static_cast<int>(input[plaintext_length_index + 1 + index]);
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z')
            buffer[index] = mapping[static_cast<std::size_t>(letter - 'A')];
        else
            buffer[index] = static_cast<std::uint8_t>(letter);
    }

    if (output == nullptr || capacity < plaintext_length) return -2;
    for (std::size_t index = 0; index < plaintext_length; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(plaintext_length);
}
