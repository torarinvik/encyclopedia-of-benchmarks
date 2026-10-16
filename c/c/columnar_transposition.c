#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 256
#define MAX_KEY 32

int64_t columnar_transposition(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    int64_t operation = input[0], text_value = input[1], raw_key_value = input[2];
    if ((operation != 0 && operation != 1) || text_value < 0 || text_value > MAX_TEXT ||
        raw_key_value < 1 || raw_key_value > MAX_KEY) return -1;
    size_t text_length = (size_t)text_value, raw_key_length = (size_t)raw_key_value;
    if (length != 3 + text_length + raw_key_length) return -1;
    uint8_t key[MAX_KEY], order[MAX_KEY];
    size_t key_length = 0;
    for (size_t i = 0; i < text_length; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    for (size_t i = 0; i < raw_key_length; ++i) {
        int64_t value = input[3 + text_length + i];
        if (value < 0 || value > 127) return -1;
        if (value >= 'A' && value <= 'Z') key[key_length++] = (uint8_t)value;
        else if (value >= 'a' && value <= 'z') key[key_length++] = (uint8_t)(value - 32);
    }
    if (key_length == 0) return -1;
    for (size_t i = 0; i < key_length; ++i) {
        order[i] = (uint8_t)i;
        size_t position = i;
        while (position > 0 && key[order[position - 1]] > key[i]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = (uint8_t)i;
    }
    if (text_length == 0) return 0;
    if (output == NULL || capacity < text_length) return -2;
    size_t rows = (text_length + key_length - 1) / key_length;
    if (operation == 0) {
        size_t written = 0;
        for (size_t rank = 0; rank < key_length; ++rank) {
            size_t column = order[rank];
            for (size_t row = 0; row < rows; ++row) {
                size_t index = row * key_length + column;
                if (index < text_length) output[written++] = (uint8_t)input[3 + index];
            }
        }
        return (int64_t)written;
    }
    uint8_t column_data[MAX_KEY][MAX_TEXT];
    size_t column_lengths[MAX_KEY], offset = 0;
    size_t short_columns = text_length % key_length;
    for (size_t column = 0; column < key_length; ++column)
        column_lengths[column] = short_columns == 0 || column < short_columns ? rows : rows - 1;
    for (size_t rank = 0; rank < key_length; ++rank) {
        size_t column = order[rank];
        for (size_t row = 0; row < column_lengths[column]; ++row)
            column_data[column][row] = (uint8_t)input[3 + offset++];
    }
    size_t written = 0;
    for (size_t row = 0; row < rows; ++row)
        for (size_t column = 0; column < key_length; ++column)
            if (row < column_lengths[column]) output[written++] = column_data[column][row];
    return (int64_t)written;
}
