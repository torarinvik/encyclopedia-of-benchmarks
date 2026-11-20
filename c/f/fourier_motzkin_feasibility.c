#include <stddef.h>
#include <stdint.h>

#define MAX_VARIABLES 3u
#define MAX_INEQUALITIES 6u
#define MAX_ROWS 128u
#define MAX_PARSEABLE_LENGTH 27u
#define ROW_WIDTH 4u

int64_t fourier_motzkin_feasibility(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t dimension_value = input[0];
    const int64_t count_value = input[1];
    if (dimension_value < 1 || dimension_value > (int64_t)MAX_VARIABLES ||
        count_value < 1 || count_value > (int64_t)MAX_INEQUALITIES) return -1;
    const size_t dimension = (size_t)dimension_value;
    const size_t count = (size_t)count_value;
    if (length != 2u + count * (dimension + 1u)) return -1;

    int64_t first[MAX_ROWS][ROW_WIDTH] = {{0}};
    int64_t second[MAX_ROWS][ROW_WIDTH] = {{0}};
    size_t offset = 2u;
    for (size_t row = 0; row < count; ++row) {
        for (size_t coordinate = 0; coordinate < dimension; ++coordinate) {
            const int64_t value = input[offset++];
            if (value < -3 || value > 3) return -1;
            first[row][coordinate] = value;
        }
        const int64_t bound = input[offset++];
        if (bound < -6 || bound > 6) return -1;
        first[row][3] = bound;
    }

    int64_t (*current)[ROW_WIDTH] = first;
    int64_t (*next)[ROW_WIDTH] = second;
    size_t row_count = count;
    for (size_t variable = 0; variable < dimension; ++variable) {
        size_t next_count = 0u;
        for (size_t row = 0; row < row_count; ++row) {
            if (current[row][variable] == 0) {
                for (size_t column = 0; column < ROW_WIDTH; ++column)
                    next[next_count][column] = current[row][column];
                ++next_count;
            }
        }
        for (size_t upper = 0; upper < row_count; ++upper) {
            const int64_t positive = current[upper][variable];
            if (positive <= 0) continue;
            for (size_t lower = 0; lower < row_count; ++lower) {
                const int64_t negative = current[lower][variable];
                if (negative >= 0) continue;
                if (next_count >= MAX_ROWS) return -1;
                const int64_t upper_scale = positive;
                const int64_t lower_scale = -negative;
                for (size_t coordinate = 0; coordinate < dimension; ++coordinate)
                    next[next_count][coordinate] = coordinate == variable ? 0 :
                        lower_scale * current[upper][coordinate] +
                        upper_scale * current[lower][coordinate];
                next[next_count][3] = lower_scale * current[upper][3] +
                                      upper_scale * current[lower][3];
                ++next_count;
            }
        }
        for (size_t row = 0; row < next_count; ++row)
            for (size_t column = 0; column < ROW_WIDTH; ++column)
                current[row][column] = next[row][column];
        for (size_t row = 0; row < MAX_ROWS; ++row)
            for (size_t column = 0; column < ROW_WIDTH; ++column)
                next[row][column] = 0;
        row_count = next_count;
    }

    for (size_t row = 0; row < row_count; ++row)
        if (current[row][3] < 0) return 0;
    return 1;
}
