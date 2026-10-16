/* Compute the six exact 5x5 determinant coefficients of a conic. */
#include <stddef.h>
#include <stdint.h>

static int64_t determinant(const int64_t features[5][6], const uint8_t columns[5])
{
    int64_t paths[32] = {0};
    paths[0] = 1;
    for (size_t row = 0; row < 5; ++row) {
        int64_t next[32] = {0};
        for (size_t mask = 0; mask < 32; ++mask) {
            size_t selected = 0;
            for (size_t bit = 0; bit < 5; ++bit) selected += (mask >> bit) & 1U;
            if (selected != row || paths[mask] == 0) continue;
            for (size_t column = 0; column < 5; ++column) {
                const size_t bit = (size_t)1 << column;
                if ((mask & bit) != 0) continue;
                size_t inversions = 0;
                for (size_t previous = column + 1; previous < 5; ++previous)
                    inversions += (mask >> previous) & 1U;
                const int64_t value = features[row][columns[column]];
                const int64_t term = paths[mask] * value;
                next[mask | bit] += (inversions & 1U) ? -term : term;
            }
        }
        for (size_t mask = 0; mask < 32; ++mask) paths[mask] = next[mask];
    }
    return paths[31];
}

int64_t braikenridge_maclaurin_construction(const int64_t *values, size_t length,
                                             uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 10) return -2;
    int64_t features[5][6];
    for (size_t point = 0; point < 5; ++point) {
        const int64_t x = values[2 * point];
        const int64_t y = values[2 * point + 1];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -2;
        features[point][0] = x * x;
        features[point][1] = x * y;
        features[point][2] = y * y;
        features[point][3] = x;
        features[point][4] = y;
        features[point][5] = 1;
    }
    static const uint8_t columns[6][5] = {
        {1, 2, 3, 4, 5}, {0, 2, 3, 4, 5}, {0, 1, 3, 4, 5},
        {0, 1, 2, 4, 5}, {0, 1, 2, 3, 5}, {0, 1, 2, 3, 4}
    };
    static const int8_t signs[6] = {1, -1, 1, -1, 1, -1};
    int64_t coefficients[6];
    for (size_t index = 0; index < 6; ++index)
        coefficients[index] = signs[index] * determinant(features, columns[index]);
    if (output_capacity < 48 || output == NULL) return -2;
    for (size_t index = 0; index < 6; ++index) {
        const uint64_t bits = (uint64_t)coefficients[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[8 * index + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return 6;
}
