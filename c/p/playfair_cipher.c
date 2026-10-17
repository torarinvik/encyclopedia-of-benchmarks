#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_KEY_LENGTH 25u
#define MAX_TEXT_LENGTH 128u
#define MAX_PARSEABLE_INPUT_VALUES (3u + MAX_KEY_LENGTH + MAX_TEXT_LENGTH + 1u)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW_63_MASK UINT64_C(0x7fffffffffffffff)

static int is_letter(int64_t value)
{
    return value >= 'A' && value <= 'Z' && value != 'J';
}

static void add_square_letter(uint8_t square[25], bool seen[128], size_t *count,
                              uint8_t letter)
{
    if (seen[letter]) return;
    seen[letter] = true;
    square[(*count)++] = letter;
}

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ (uint64_t)byte) * FNV_PRIME;
}

int64_t playfair_cipher(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    const int64_t operation = values[0];
    const int64_t raw_key_length = values[1];
    if ((operation != 0 && operation != 1) || raw_key_length < 0 ||
        raw_key_length > (int64_t)MAX_KEY_LENGTH) return -1;

    const size_t key_length = (size_t)raw_key_length;
    const size_t text_length_index = 2u + key_length;
    if (length <= text_length_index) return -1;
    const int64_t raw_text_length = values[text_length_index];
    if (raw_text_length < 0 || raw_text_length > (int64_t)MAX_TEXT_LENGTH ||
        (raw_text_length & 1) != 0) return -1;
    const size_t text_length = (size_t)raw_text_length;
    if (length != text_length_index + 1u + text_length) return -1;

    uint8_t key[MAX_KEY_LENGTH];
    uint8_t text[MAX_TEXT_LENGTH];
    for (size_t index = 0u; index < key_length; ++index) {
        const int64_t value = values[2u + index];
        if (!is_letter(value)) return -1;
        key[index] = (uint8_t)value;
    }
    for (size_t index = 0u; index < text_length; ++index) {
        const int64_t value = values[text_length_index + 1u + index];
        if (!is_letter(value)) return -1;
        text[index] = (uint8_t)value;
    }
    if (operation == 0) {
        for (size_t index = 0u; index + 1u < text_length; ++index) {
            if (text[index] == text[index + 1u]) return -1;
        }
    }

    static const uint8_t alphabet[] = "ABCDEFGHIKLMNOPQRSTUVWXYZ";
    uint8_t square[25];
    bool seen[128] = {false};
    size_t square_length = 0u;
    for (size_t index = 0u; index < key_length; ++index) {
        add_square_letter(square, seen, &square_length, key[index]);
    }
    for (size_t index = 0u; index < 25u; ++index) {
        add_square_letter(square, seen, &square_length, alphabet[index]);
    }

    int position[128];
    for (size_t index = 0u; index < 128u; ++index) position[index] = -1;
    for (size_t index = 0u; index < square_length; ++index) {
        position[square[index]] = (int)index;
    }

    uint64_t hash = FNV_OFFSET_BASIS;
    const int direction = operation == 0 ? 1 : -1;
    for (size_t index = 0u; index < text_length; index += 2u) {
        const int first = position[text[index]];
        const int second = position[text[index + 1u]];
        const int row1 = first / 5;
        const int column1 = first % 5;
        const int row2 = second / 5;
        const int column2 = second % 5;
        uint8_t output_first;
        uint8_t output_second;

        if (row1 == row2) {
            const int next_column1 = (column1 + direction + 5) % 5;
            const int next_column2 = (column2 + direction + 5) % 5;
            output_first = square[row1 * 5 + next_column1];
            output_second = square[row2 * 5 + next_column2];
        } else if (column1 == column2) {
            const int next_row1 = (row1 + direction + 5) % 5;
            const int next_row2 = (row2 + direction + 5) % 5;
            output_first = square[next_row1 * 5 + column1];
            output_second = square[next_row2 * 5 + column2];
        } else {
            output_first = square[row1 * 5 + column2];
            output_second = square[row2 * 5 + column1];
        }

        hash = hash_byte(hash, output_first);
        hash = hash_byte(hash, output_second);
    }

    return (int64_t)(hash & LOW_63_MASK);
}
