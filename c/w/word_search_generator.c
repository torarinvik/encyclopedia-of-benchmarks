#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_DIMENSION 32
#define MAX_CELLS 1024
#define MAX_WORDS 96
#define MAX_WORD_LENGTH 32
#define MAX_INPUT_VALUES 4096
#define RNG_MODULUS UINT64_C(2147483647)

static uint64_t next_random(uint64_t *state)
{
    *state = (*state * UINT64_C(48271)) % RNG_MODULUS;
    return *state;
}

static void shuffle(size_t *items, size_t count, uint64_t *state)
{
    for (size_t remaining = count; remaining > 1; --remaining) {
        const size_t other = (size_t)(next_random(state) % remaining);
        const size_t temporary = items[remaining - 1];
        items[remaining - 1] = items[other];
        items[other] = temporary;
    }
}

static int is_ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

int64_t word_search_generator(const int64_t *values, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 4 || length > MAX_INPUT_VALUES) return -1;
    const int64_t width_value = values[0];
    const int64_t height_value = values[1];
    const int64_t seed_value = values[2];
    const int64_t word_count_value = values[3];
    if (width_value < 1 || width_value > MAX_DIMENSION ||
        height_value < 1 || height_value > MAX_DIMENSION ||
        seed_value < 1 || seed_value >= (int64_t)RNG_MODULUS ||
        word_count_value < 0 || word_count_value > MAX_WORDS) return -1;

    const size_t width = (size_t)width_value;
    const size_t height = (size_t)height_value;
    const size_t word_count = (size_t)word_count_value;
    size_t position = 4;
    for (size_t word = 0; word < word_count; ++word) {
        if (position >= length) return -1;
        const int64_t word_length_value = values[position++];
        if (word_length_value < 1 || word_length_value > MAX_WORD_LENGTH ||
            (uint64_t)word_length_value > length - position) return -1;
        const size_t word_length = (size_t)word_length_value;
        for (size_t offset = 0; offset < word_length; ++offset) {
            if (!is_ascii_letter(values[position + offset])) return -1;
        }
        position += word_length;
    }
    if (position != length) return -1;

    const size_t cells = width * height;
    if (output == NULL || output_capacity < cells) return -2;
    uint8_t board[MAX_CELLS] = {0};
    static const int row_delta[8] = {-1, -1, 0, 1, 1, 1, 0, -1};
    static const int column_delta[8] = {0, 1, 1, 1, 0, -1, -1, -1};
    uint64_t state = (uint64_t)seed_value;
    position = 4;

    for (size_t word = 0; word < word_count; ++word) {
        const size_t word_length = (size_t)values[position++];
        const size_t word_start = position;
        position += word_length;
        size_t rows[MAX_DIMENSION];
        size_t columns[MAX_DIMENSION];
        for (size_t row = 0; row < height; ++row) rows[row] = row;
        for (size_t column = 0; column < width; ++column) columns[column] = column;
        shuffle(rows, height, &state);
        shuffle(columns, width, &state);
        const size_t direction = (size_t)(next_random(&state) % 8);
        int placed = 0;

        for (size_t row_index = 0; row_index < height && !placed; ++row_index) {
            for (size_t column_index = 0; column_index < width && !placed; ++column_index) {
                const int row = (int)rows[row_index];
                const int column = (int)columns[column_index];
                const int last_row = row + ((int)word_length - 1) * row_delta[direction];
                const int last_column = column + ((int)word_length - 1) * column_delta[direction];
                if (last_row < 0 || last_row >= (int)height ||
                    last_column < 0 || last_column >= (int)width) continue;
                int available = 1;
                for (size_t offset = 0; offset < word_length; ++offset) {
                    const int current_row = row + (int)offset * row_delta[direction];
                    const int current_column = column + (int)offset * column_delta[direction];
                    if (board[(size_t)current_row * width + (size_t)current_column] != 0) {
                        available = 0;
                        break;
                    }
                }
                if (!available) continue;
                for (size_t offset = 0; offset < word_length; ++offset) {
                    const int current_row = row + (int)offset * row_delta[direction];
                    const int current_column = column + (int)offset * column_delta[direction];
                    board[(size_t)current_row * width + (size_t)current_column] =
                        (uint8_t)values[word_start + offset];
                }
                placed = 1;
            }
        }
    }
    memcpy(output, board, cells);
    return (int64_t)cells;
}
