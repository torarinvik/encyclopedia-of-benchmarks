#include <cstddef>
#include <cstdint>

#define MIN_RUNS INT64_C(1)
#define MAX_RUNS INT64_C(100)
#define SOLVE_REPETITIONS 50
#define MAX_OUTPUT_BYTES 292

static int try_queens(int row, int *columns, int *diagonal_sum, int *diagonal_diff, int *positions) {
    int j = 0;
    int found = 0;
    while (!found && j != 8) {
        ++j;
        found = 0;
        if (columns[j] && diagonal_sum[row + j] && diagonal_diff[row - j + 7]) {
            positions[row] = j;
            columns[j] = 0;
            diagonal_sum[row + j] = 0;
            diagonal_diff[row - j + 7] = 0;
            if (row < 8) {
                found = try_queens(row + 1, columns, diagonal_sum, diagonal_diff, positions);
                if (!found) {
                    columns[j] = 1;
                    diagonal_sum[row + j] = 1;
                    diagonal_diff[row - j + 7] = 1;
                }
            } else {
                found = 1;
            }
        }
    }
    return found;
}

static int doit() {
    int a[9] = {0};
    int b[17] = {0};
    int c[15] = {0};
    int x[9] = {0};
    for (int i = -7; i <= 16; ++i) {
        if (i >= 1 && i <= 8) a[i] = 1;
        if (i >= 2) b[i] = 1;
        if (i <= 7) c[i + 7] = 1;
    }
    return try_queens(1, a, b, c, x);
}

static void append_text(uint8_t *buffer, size_t *used, const char *text) {
    while (*text != '\0') buffer[(*used)++] = (uint8_t)*text++;
}

static void append_integer(uint8_t *buffer, size_t *used, int32_t value) {
    uint8_t reverse[12];
    size_t count = 0;
    int32_t remaining = value;
    do {
        reverse[count++] = (uint8_t)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) buffer[(*used)++] = reverse[--count];
}

extern "C" int64_t stanford_queens(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == nullptr) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    for (int32_t run = 0; run < (int32_t)runs; ++run) {
        for (int repetition = 0; repetition < SOLVE_REPETITIONS; ++repetition) {
            if (!doit()) append_text(staged, &used, " Error in Queens.\n");
        }
        append_integer(staged, &used, run + 1);
        append_text(staged, &used, "\n");
    }
    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
