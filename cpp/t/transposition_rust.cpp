#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_KEYS = 4;
constexpr std::size_t MAX_KEY_LENGTH = 32;
constexpr std::size_t MAX_MESSAGE_LENGTH = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH;
constexpr std::size_t MAX_OUTPUT_LENGTH = 2 * MAX_MESSAGE_LENGTH - 1;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
constexpr std::uint64_t LOW63_MASK = UINT64_C(0x7fffffffffffffff);

bool is_ascii_letter(std::int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

std::size_t normalize(const std::uint8_t *input, std::size_t length, std::uint8_t *output) {
    std::size_t count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        std::uint8_t ch = input[i];
        if (ch >= 'a' && ch <= 'z') ch = static_cast<std::uint8_t>(ch - ('a' - 'A'));
        if (ch >= 'A' && ch <= 'Z') output[count++] = ch;
    }
    return count;
}

void column_order(const std::uint8_t *key, std::size_t key_length, std::size_t *order) {
    for (std::size_t i = 0; i < key_length; ++i) order[i] = i;
    for (std::size_t i = 1; i < key_length; ++i) {
        const std::size_t column = order[i];
        std::size_t position = i;
        while (position > 0 && key[order[position - 1]] > key[column]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = column;
    }
}

std::size_t encrypt_round(const std::uint8_t *text, std::size_t text_length,
                          const std::uint8_t *key, std::size_t key_length,
                          std::uint8_t *output) {
    std::size_t order[MAX_KEY_LENGTH];
    std::uint8_t columns[MAX_MESSAGE_LENGTH];
    std::size_t ordered_length = 0;
    column_order(key, key_length, order);
    for (std::size_t rank = 0; rank < key_length; ++rank)
        for (std::size_t position = order[rank]; position < text_length; position += key_length)
            columns[ordered_length++] = text[position];

    const std::size_t group_size = (text_length + key_length - 1) / key_length;
    std::size_t output_length = 0;
    for (std::size_t i = 0; i < ordered_length; ++i) {
        output[output_length++] = columns[i];
        if ((i + 1) % group_size == 0 && i + 1 < ordered_length) output[output_length++] = ' ';
    }
    return output_length;
}

std::size_t decrypt_round(const std::uint8_t *text, std::size_t text_length,
                          const std::uint8_t *key, std::size_t key_length,
                          std::uint8_t *output) {
    std::size_t order[MAX_KEY_LENGTH];
    std::uint8_t columns[MAX_KEY_LENGTH][MAX_MESSAGE_LENGTH]{};
    std::size_t column_lengths[MAX_KEY_LENGTH]{};
    column_order(key, key_length, order);
    const std::size_t short_length = text_length / key_length;
    const std::size_t longer_columns = text_length % key_length;
    std::size_t cursor = 0;
    for (std::size_t rank = 0; rank < key_length; ++rank) {
        const std::size_t column = order[rank];
        const std::size_t length = short_length + (column < longer_columns ? 1 : 0);
        column_lengths[column] = length;
        for (std::size_t row = 0; row < length; ++row) columns[column][row] = text[cursor++];
    }
    std::size_t output_length = 0;
    const std::size_t row_count = short_length + (longer_columns > 0 ? 1 : 0);
    for (std::size_t row = 0; row < row_count; ++row)
        for (std::size_t column = 0; column < key_length; ++column)
            if (row < column_lengths[column]) output[output_length++] = columns[column][row];
    return output_length;
}

std::uint64_t hash_output(const std::uint8_t *text, std::size_t length) {
    std::uint64_t hash = FNV_OFFSET;
    std::uint64_t length_bits = static_cast<std::uint64_t>(length);
    for (int byte = 0; byte < 8; ++byte) {
        hash = (hash ^ static_cast<std::uint8_t>(length_bits & UINT64_C(255))) * FNV_PRIME;
        length_bits >>= 8;
    }
    for (std::size_t i = 0; i < length; ++i) {
        std::uint32_t codepoint = text[i];
        for (int byte = 0; byte < 4; ++byte) {
            hash = (hash ^ static_cast<std::uint8_t>(codepoint & UINT32_C(255))) * FNV_PRIME;
            codepoint >>= 8;
        }
    }
    return hash & LOW63_MASK;
}
}

extern "C" std::int64_t transposition_rust(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t mode = input[0], key_count_value = input[1];
    if ((mode != 0 && mode != 1) || key_count_value < 1 || key_count_value > static_cast<std::int64_t>(MAX_KEYS)) return -1;
    const std::size_t key_count = static_cast<std::size_t>(key_count_value);

    std::uint8_t keys[MAX_KEYS][MAX_KEY_LENGTH]{};
    std::size_t key_lengths[MAX_KEYS]{};
    std::size_t longest_key = 0, cursor = 2;
    for (std::size_t key_index = 0; key_index < key_count; ++key_index) {
        if (cursor >= length) return -1;
        const std::int64_t key_length_value = input[cursor++];
        if (key_length_value < 1 || key_length_value > static_cast<std::int64_t>(MAX_KEY_LENGTH)) return -1;
        const std::size_t key_length = static_cast<std::size_t>(key_length_value);
        if (key_length > length - cursor) return -1;
        for (std::size_t i = 0; i < key_length; ++i) {
            const std::int64_t value = input[cursor + i];
            if (!is_ascii_letter(value)) return -1;
            std::uint8_t ch = static_cast<std::uint8_t>(value);
            if (ch >= 'a' && ch <= 'z') ch = static_cast<std::uint8_t>(ch - ('a' - 'A'));
            keys[key_index][i] = ch;
        }
        cursor += key_length;
        key_lengths[key_index] = key_length;
        if (key_length > longest_key) longest_key = key_length;
    }
    if (cursor >= length) return -1;
    const std::int64_t message_length_value = input[cursor++];
    if (message_length_value < 1 || message_length_value > static_cast<std::int64_t>(MAX_MESSAGE_LENGTH)) return -1;
    const std::size_t message_length = static_cast<std::size_t>(message_length_value);
    if (message_length != length - cursor) return -1;

    std::uint8_t message[MAX_MESSAGE_LENGTH];
    for (std::size_t i = 0; i < message_length; ++i) {
        const std::int64_t value = input[cursor + i];
        if (value < 0 || value > 127) return -1;
        message[i] = static_cast<std::uint8_t>(value);
    }
    std::uint8_t current[MAX_OUTPUT_LENGTH]{}, filtered[MAX_MESSAGE_LENGTH]{}, next[MAX_OUTPUT_LENGTH]{};
    std::size_t current_length = normalize(message, message_length, current);
    if (current_length < longest_key) return -1;
    for (std::size_t pass = 0; pass < key_count; ++pass) {
        const std::size_t key_index = mode == 0 ? pass : key_count - 1 - pass;
        const std::size_t filtered_length = normalize(current, current_length, filtered);
        const std::size_t next_length = mode == 0
            ? encrypt_round(filtered, filtered_length, keys[key_index], key_lengths[key_index], next)
            : decrypt_round(filtered, filtered_length, keys[key_index], key_lengths[key_index], next);
        for (std::size_t i = 0; i < next_length; ++i) current[i] = next[i];
        current_length = next_length;
    }
    return static_cast<std::int64_t>(hash_output(current, current_length));
}
