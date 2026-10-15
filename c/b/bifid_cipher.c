/* Fractionate a fixed-square Bifid cipher over one complete message block. */
#include <stddef.h>
#include <stdint.h>

static int letter_index(int64_t value, int merge_j)
{
    if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
    if (value < 'A' || value > 'Z') return -1;
    int index = (int)(value - 'A');
    if (index == 9) {
        if (!merge_j) return -1;
        index = 8;
    } else if (index > 9) {
        --index;
    }
    return index;
}

static uint8_t letter_for_index(size_t index)
{
    int value = 'a' + (int)index;
    if (index >= 9) ++value;
    return (uint8_t)value;
}

int64_t bifid_cipher(const int64_t *input, size_t length, uint8_t *output,
                     size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 258) return -1;
    const int64_t mode = input[0];
    const int64_t text_length_value = input[1];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 256)
        return -1;
    const size_t text_length = (size_t)text_length_value;
    if (length != text_length + 2) return -1;

    uint8_t rows[256];
    uint8_t columns[256];
    uint8_t coordinates[512];
    uint8_t result[256];
    size_t result_length = 0;

    if (mode == 0) {
        for (size_t i = 0; i < text_length; ++i) {
            const int64_t value = input[i + 2];
            if (value == ' ') continue;
            const int index = letter_index(value, 1);
            if (index < 0) return -1;
            rows[result_length] = (uint8_t)(index / 5 + 1);
            columns[result_length] = (uint8_t)(index % 5 + 1);
            ++result_length;
        }
        for (size_t i = 0; i < result_length; ++i) {
            coordinates[i] = rows[i];
            coordinates[result_length + i] = columns[i];
        }
        for (size_t i = 0; i < result_length; ++i) {
            const size_t letter_index_value =
                (size_t)(coordinates[2 * i] - 1) * 5 + (coordinates[2 * i + 1] - 1);
            result[i] = letter_for_index(letter_index_value);
        }
    } else {
        result_length = text_length;
        for (size_t i = 0; i < text_length; ++i) {
            const int index = letter_index(input[i + 2], 0);
            if (index < 0) return -1;
            coordinates[2 * i] = (uint8_t)(index / 5 + 1);
            coordinates[2 * i + 1] = (uint8_t)(index % 5 + 1);
        }
        for (size_t i = 0; i < result_length; ++i) {
            const size_t letter_index_value =
                (size_t)(coordinates[i] - 1) * 5 + (coordinates[result_length + i] - 1);
            result[i] = letter_for_index(letter_index_value);
        }
    }

    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return (int64_t)result_length;
}
