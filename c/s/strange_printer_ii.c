#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS INT64_C(6)
#define MAX_COLUMNS INT64_C(6)
#define MAX_COLORS INT64_C(6)
#define COLOR_SIDE 7

int64_t strange_printer_ii(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 39) return -1;
    const int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)rows_raw, columns = (size_t)columns_raw;
    if (length != 2 + rows * columns) return -1;
    for (size_t cell = 0; cell < rows * columns; ++cell) {
        if (input[cell + 2] < 1 || input[cell + 2] > MAX_COLORS) return -1;
    }

    int64_t first_row[COLOR_SIDE], last_row[COLOR_SIDE];
    int64_t first_column[COLOR_SIDE], last_column[COLOR_SIDE];
    int64_t outgoing[COLOR_SIDE] = {0}, indegree[COLOR_SIDE] = {0};
    int64_t queue[COLOR_SIDE] = {0};
    for (size_t color = 0; color < COLOR_SIDE; ++color) {
        first_row[color] = rows_raw;
        last_row[color] = -1;
        first_column[color] = columns_raw;
        last_column[color] = -1;
    }
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            const int64_t color = input[2 + row * columns + column];
            if ((int64_t)row < first_row[color]) first_row[color] = (int64_t)row;
            if ((int64_t)row > last_row[color]) last_row[color] = (int64_t)row;
            if ((int64_t)column < first_column[color]) first_column[color] = (int64_t)column;
            if ((int64_t)column > last_column[color]) last_column[color] = (int64_t)column;
        }
    }

    int64_t present_count = 0;
    for (int64_t color = 1; color <= MAX_COLORS; ++color) {
        if (last_row[color] < 0) continue;
        ++present_count;
        for (int64_t row = first_row[color]; row <= last_row[color]; ++row) {
            for (int64_t column = first_column[color]; column <= last_column[color]; ++column) {
                const int64_t covered = input[2 + (size_t)row * columns + (size_t)column];
                const int64_t bit = INT64_C(1) << covered;
                if (covered != color && (outgoing[color] & bit) == 0) {
                    outgoing[color] |= bit;
                    ++indegree[covered];
                }
            }
        }
    }

    size_t head = 0, tail = 0;
    for (int64_t color = 1; color <= MAX_COLORS; ++color) {
        if (last_row[color] >= 0 && indegree[color] == 0) queue[tail++] = color;
    }
    int64_t processed = 0;
    while (head < tail) {
        const int64_t color = queue[head++];
        ++processed;
        for (int64_t later = 1; later <= MAX_COLORS; ++later) {
            if ((outgoing[color] & (INT64_C(1) << later)) != 0) {
                if (--indegree[later] == 0) queue[tail++] = later;
            }
        }
    }
    return processed == present_count ? 1 : 0;
}
