#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cards = 12;
constexpr std::size_t max_input_words = 14;
constexpr std::size_t deck_size = 81;

int complement_code(int a, int b) noexcept {
    int result = 0;
    int place = 1;
    for (int feature = 0; feature < 4; ++feature) {
        const int digit_sum = (a / place) % 3 + (b / place) % 3;
        result += ((3 - digit_sum % 3) % 3) * place;
        place *= 3;
    }
    return result;
}

void put_i64_le(std::uint8_t *output, std::size_t offset,
                std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t set_puzzle_find_sets(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_words) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_cards) ||
        length != static_cast<std::size_t>(raw_count) + 1) return -1;

    std::int8_t index_by_code[deck_size];
    std::int8_t code_by_index[max_cards];
    for (std::size_t code = 0; code < deck_size; ++code) index_by_code[code] = -1;
    const auto count = static_cast<std::size_t>(raw_count);
    for (std::size_t i = 0; i < count; ++i) {
        const auto code = input[i + 1];
        if (code < 0 || code >= static_cast<std::int64_t>(deck_size) ||
            index_by_code[code] >= 0) return -1;
        index_by_code[code] = static_cast<std::int8_t>(i);
        code_by_index[i] = static_cast<std::int8_t>(code);
    }

    std::size_t set_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t j = i + 1; j < count; ++j) {
            const int k = index_by_code[complement_code(code_by_index[i], code_by_index[j])];
            if (k > static_cast<int>(j)) ++set_count;
        }
    }

    const auto output_bytes = (1 + 3 * set_count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    put_i64_le(output, 0, static_cast<std::int64_t>(set_count));
    std::size_t word = 1;
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t j = i + 1; j < count; ++j) {
            const int k = index_by_code[complement_code(code_by_index[i], code_by_index[j])];
            if (k > static_cast<int>(j)) {
                put_i64_le(output, word++ * 8, static_cast<std::int64_t>(i));
                put_i64_le(output, word++ * 8, static_cast<std::int64_t>(j));
                put_i64_le(output, word++ * 8, k);
            }
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
