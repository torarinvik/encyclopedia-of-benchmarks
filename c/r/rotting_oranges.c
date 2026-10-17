#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 256
#define MAX_INPUT_LENGTH 259
#define INVALID_RESULT INT64_MIN

int64_t rotting_oranges(const int64_t *input, size_t length)
{
    if (input == NULL) return length == 0 ? 0 : INVALID_RESULT;
    if (length == 0) return 0;
    if (length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;

    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value == 0) {
        return columns_value == 0 && length == 2 ? 0 : INVALID_RESULT;
    }
    if (rows_value < 1 || rows_value > 16 || columns_value < 0 || columns_value > 16) {
        return INVALID_RESULT;
    }

    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t cell_count = rows * columns;
    if (length != 2 + cell_count) return INVALID_RESULT;

    uint8_t cells[MAX_CELLS];
    size_t queue[MAX_CELLS];
    uint16_t distance[MAX_CELLS] = {0};
    size_t head = 0, tail = 0;
    size_t fresh = 0, rotted = 0;
    for (size_t index = 0; index < cell_count; ++index) {
        const int64_t value = input[2 + index];
        if (value < 0 || value > 2) return INVALID_RESULT;
        cells[index] = (uint8_t)value;
        if (value == 1) ++fresh;
        else if (value == 2) queue[tail++] = index;
    }
    if (columns == 0 || fresh == 0) return 0;

    uint16_t minutes = 0;
    while (head < tail) {
        const size_t index = queue[head++];
        const size_t row = index / columns;
        const size_t column = index % columns;
        const uint16_t next_distance = (uint16_t)(distance[index] + 1);
        size_t neighbors[4];
        size_t neighbor_count = 0;
        if (row > 0) neighbors[neighbor_count++] = index - columns;
        if (column + 1 < columns) neighbors[neighbor_count++] = index + 1;
        if (row + 1 < rows) neighbors[neighbor_count++] = index + columns;
        if (column > 0) neighbors[neighbor_count++] = index - 1;
        for (size_t offset = 0; offset < neighbor_count; ++offset) {
            const size_t next = neighbors[offset];
            if (cells[next] != 1) continue;
            cells[next] = 2;
            distance[next] = next_distance;
            if (next_distance > minutes) minutes = next_distance;
            ++rotted;
            queue[tail++] = next;
        }
    }
    return rotted == fresh ? (int64_t)minutes : -1;
}
