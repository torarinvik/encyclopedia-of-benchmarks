#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS 4
#define MAX_KEY_LENGTH 32
#define MAX_MESSAGE_LENGTH 256
#define MAX_INPUT_LENGTH (3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH)
#define MAX_OUTPUT_LENGTH (2 * MAX_MESSAGE_LENGTH - 1)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW63_MASK UINT64_C(0x7fffffffffffffff)

static int is_ascii_letter(int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static size_t normalize(const uint8_t *input, size_t length, uint8_t *output) {
    size_t count = 0;
    for (size_t i = 0; i < length; ++i) {
        uint8_t ch = input[i];
        if (ch >= 'a' && ch <= 'z') ch = (uint8_t)(ch - ('a' - 'A'));
        if (ch >= 'A' && ch <= 'Z') output[count++] = ch;
    }
    return count;
}

static void column_order(const uint8_t *key, size_t key_length, size_t *order) {
    for (size_t i = 0; i < key_length; ++i) order[i] = i;
    for (size_t i = 1; i < key_length; ++i) {
        const size_t column = order[i];
        size_t position = i;
        while (position > 0 && key[order[position - 1]] > key[column]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = column;
    }
}

static size_t encrypt_round(const uint8_t *text, size_t text_length,
                            const uint8_t *key, size_t key_length,
                            uint8_t *output) {
    size_t order[MAX_KEY_LENGTH];
    uint8_t columns[MAX_MESSAGE_LENGTH];
    size_t ordered_length = 0;
    column_order(key, key_length, order);
    for (size_t rank = 0; rank < key_length; ++rank) {
        for (size_t position = order[rank]; position < text_length; position += key_length)
            columns[ordered_length++] = text[position];
    }

    const size_t group_size = (text_length + key_length - 1) / key_length;
    size_t output_length = 0;
    for (size_t i = 0; i < ordered_length; ++i) {
        output[output_length++] = columns[i];
        if ((i + 1) % group_size == 0 && i + 1 < ordered_length)
            output[output_length++] = ' ';
    }
    return output_length;
}

static size_t decrypt_round(const uint8_t *text, size_t text_length,
                            const uint8_t *key, size_t key_length,
                            uint8_t *output) {
    size_t order[MAX_KEY_LENGTH];
    uint8_t columns[MAX_KEY_LENGTH][MAX_MESSAGE_LENGTH] = {{0}};
    size_t column_lengths[MAX_KEY_LENGTH] = {0};
    column_order(key, key_length, order);

    const size_t short_length = text_length / key_length;
    const size_t longer_columns = text_length % key_length;
    size_t cursor = 0;
    for (size_t rank = 0; rank < key_length; ++rank) {
        const size_t column = order[rank];
        const size_t column_length = short_length + (column < longer_columns ? 1 : 0);
        column_lengths[column] = column_length;
        for (size_t row = 0; row < column_length; ++row)
            columns[column][row] = text[cursor++];
    }

    size_t output_length = 0;
    const size_t row_count = short_length + (longer_columns > 0 ? 1 : 0);
    for (size_t row = 0; row < row_count; ++row)
        for (size_t column = 0; column < key_length; ++column)
            if (row < column_lengths[column]) output[output_length++] = columns[column][row];
    return output_length;
}

static uint64_t hash_output(const uint8_t *text, size_t length) {
    uint64_t hash = FNV_OFFSET;
    uint64_t length_bits = (uint64_t)length;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash = (hash ^ (uint8_t)(length_bits & UINT64_C(255))) * FNV_PRIME;
        length_bits >>= 8;
    }
    for (size_t i = 0; i < length; ++i) {
        uint32_t codepoint = text[i];
        for (unsigned byte = 0; byte < 4; ++byte) {
            hash = (hash ^ (uint8_t)(codepoint & UINT32_C(255))) * FNV_PRIME;
            codepoint >>= 8;
        }
    }
    return hash & LOW63_MASK;
}

int64_t transposition_rust(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t mode = input[0];
    const int64_t key_count_value = input[1];
    if ((mode != 0 && mode != 1) || key_count_value < 1 || key_count_value > MAX_KEYS) return -1;
    const size_t key_count = (size_t)key_count_value;

    uint8_t keys[MAX_KEYS][MAX_KEY_LENGTH] = {{0}};
    size_t key_lengths[MAX_KEYS] = {0};
    size_t longest_key = 0;
    size_t cursor = 2;
    for (size_t key_index = 0; key_index < key_count; ++key_index) {
        if (cursor >= length) return -1;
        const int64_t key_length_value = input[cursor++];
        if (key_length_value < 1 || key_length_value > MAX_KEY_LENGTH) return -1;
        const size_t key_length = (size_t)key_length_value;
        if (key_length > length - cursor) return -1;
        for (size_t i = 0; i < key_length; ++i) {
            const int64_t value = input[cursor + i];
            if (!is_ascii_letter(value)) return -1;
            uint8_t ch = (uint8_t)value;
            if (ch >= 'a' && ch <= 'z') ch = (uint8_t)(ch - ('a' - 'A'));
            keys[key_index][i] = ch;
        }
        cursor += key_length;
        key_lengths[key_index] = key_length;
        if (key_length > longest_key) longest_key = key_length;
    }

    if (cursor >= length) return -1;
    const int64_t message_length_value = input[cursor++];
    if (message_length_value < 1 || message_length_value > MAX_MESSAGE_LENGTH) return -1;
    const size_t message_length = (size_t)message_length_value;
    if (message_length != length - cursor) return -1;

    uint8_t message[MAX_MESSAGE_LENGTH];
    for (size_t i = 0; i < message_length; ++i) {
        const int64_t value = input[cursor + i];
        if (value < 0 || value > 127) return -1;
        message[i] = (uint8_t)value;
    }

    uint8_t current[MAX_OUTPUT_LENGTH] = {0};
    uint8_t filtered[MAX_MESSAGE_LENGTH] = {0};
    uint8_t next[MAX_OUTPUT_LENGTH] = {0};
    size_t current_length = normalize(message, message_length, current);
    if (current_length < longest_key) return -1;

    for (size_t pass = 0; pass < key_count; ++pass) {
        const size_t key_index = mode == 0 ? pass : key_count - 1 - pass;
        const size_t filtered_length = normalize(current, current_length, filtered);
        const size_t next_length = mode == 0
            ? encrypt_round(filtered, filtered_length, keys[key_index], key_lengths[key_index], next)
            : decrypt_round(filtered, filtered_length, keys[key_index], key_lengths[key_index], next);
        for (size_t i = 0; i < next_length; ++i) current[i] = next[i];
        current_length = next_length;
    }
    return (int64_t)hash_output(current, current_length);
}
