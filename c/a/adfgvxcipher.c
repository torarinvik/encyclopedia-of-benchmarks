#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_PLAINTEXT 256
#define MAX_CIPHERTEXT 512
#define MAX_KEY 16
#define MAX_ROWS 512

static const unsigned char LABELS[6] = {'A', 'D', 'F', 'G', 'V', 'X'};
static const unsigned char SQUARE[36] = {
    'N','A','1','C','3','H', '8','T','B','2','O','M',
    'E','5','W','R','P','D', '4','F','6','G','7','I',
    '9','J','0','K','L','Q', 'S','U','V','X','Y','Z'
};

static int polybius_cell(unsigned char value)
{
    for (int cell = 0; cell < 36; ++cell)
        if (SQUARE[cell] == value) return cell;
    return -1;
}

static int label_index(unsigned char value)
{
    for (int i = 0; i < 6; ++i)
        if (LABELS[i] == value) return i;
    return -1;
}

static void sort_key_order(const int64_t *input, size_t key_start, size_t key_length,
                           size_t order[MAX_KEY])
{
    for (size_t i = 0; i < key_length; ++i) order[i] = i;
    for (size_t i = 1; i < key_length; ++i) {
        const size_t current = order[i];
        size_t j = i;
        while (j > 0 && input[key_start + order[j - 1]] > input[key_start + current]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = current;
    }
}

int64_t adfgvxcipher(const int64_t *input, size_t length, uint8_t *output,
                     size_t output_capacity)
{
    if (input == NULL || length < 3) return -1;
    const int64_t mode = input[0], text_length_value = input[1], key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > MAX_KEY)
        return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t key_length = (size_t)key_length_value;
    if ((mode == 0 && text_length > MAX_PLAINTEXT) || (mode == 1 && text_length > MAX_CIPHERTEXT) ||
        length != 3 + text_length + key_length) return -1;

    for (size_t i = 0; i < text_length; ++i) {
        if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
        if (mode == 1 && label_index((unsigned char)input[3 + i]) < 0) return -1;
    }
    if (mode == 1 && (text_length & 1u) != 0) return -1;

    const size_t key_start = 3 + text_length;
    for (size_t i = 0; i < key_length; ++i) {
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
        for (size_t j = 0; j < i; ++j)
            if (input[key_start + i] == input[key_start + j]) return -1;
    }

    size_t order[MAX_KEY];
    sort_key_order(input, key_start, key_length, order);
    unsigned char result[MAX_CIPHERTEXT];
    size_t result_length = 0;

    if (mode == 0) {
        unsigned char fractionated[MAX_CIPHERTEXT];
        size_t fractionated_length = 0;
        for (size_t i = 0; i < text_length; ++i) {
            unsigned char value = (unsigned char)input[3 + i];
            if (value >= 'a' && value <= 'z') value = (unsigned char)(value - 'a' + 'A');
            if (!((value >= 'A' && value <= 'Z') || (value >= '0' && value <= '9'))) continue;
            const int cell = polybius_cell(value);
            if (cell < 0) return -1;
            fractionated[fractionated_length++] = LABELS[cell / 6];
            fractionated[fractionated_length++] = LABELS[cell % 6];
        }
        const size_t rows = (fractionated_length + key_length - 1) / key_length;
        unsigned char table[MAX_ROWS][MAX_KEY];
        memset(table, '_', sizeof table);
        for (size_t i = 0; i < fractionated_length; ++i)
            table[i / key_length][i % key_length] = fractionated[i];
        for (size_t position = 0; position < key_length; ++position) {
            const size_t column = order[position];
            for (size_t row = 0; row < rows; ++row)
                if (table[row][column] != '_') result[result_length++] = table[row][column];
        }
    } else {
        const size_t rows = (text_length + key_length - 1) / key_length;
        unsigned char table[MAX_ROWS][MAX_KEY];
        size_t source_index = 0;
        for (size_t position = 0; position < key_length; ++position) {
            const size_t column = order[position];
            for (size_t row = 0; row < rows; ++row) {
                table[row][column] = source_index < text_length ? (unsigned char)input[3 + source_index++] : '_';
            }
        }
        unsigned char fractionated[MAX_CIPHERTEXT];
        size_t fractionated_length = 0;
        for (size_t row = 0; row < rows; ++row)
            for (size_t column = 0; column < key_length; ++column)
                if (table[row][column] != '_') fractionated[fractionated_length++] = table[row][column];
        for (size_t i = 0; i < fractionated_length; i += 2) {
            const int row = label_index(fractionated[i]);
            const int column = label_index(fractionated[i + 1]);
            if (row < 0 || column < 0) return -1;
            result[result_length++] = SQUARE[row * 6 + column];
        }
    }

    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    if (result_length != 0) memcpy(output, result, result_length);
    return (int64_t)result_length;
}
