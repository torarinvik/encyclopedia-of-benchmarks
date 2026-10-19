/* Port the fixed-size integer matrix multiplication from Stanford IntMM. */
#include <stddef.h>
#include <stdint.h>

enum { ROWSIZE = 40, CELL_COUNT = ROWSIZE * ROWSIZE, MAX_PASSES = 10 };

static size_t decimal_width(int32_t value)
{
    uint32_t magnitude = value < 0 ? (uint32_t)(-(int64_t)value) : (uint32_t)value;
    size_t width = value < 0 ? 1 : 0;
    do { ++width; magnitude /= 10; } while (magnitude != 0);
    return width;
}

static size_t write_decimal(int32_t value, uint8_t *output, size_t position)
{
    uint32_t magnitude = value < 0 ? (uint32_t)(-(int64_t)value) : (uint32_t)value;
    uint8_t reversed[10];
    size_t count = 0;
    if (value < 0) output[position++] = (uint8_t)'-';
    do {
        reversed[count++] = (uint8_t)('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

int64_t stanford_intmm(int64_t pass_count, uint8_t *output, size_t output_capacity)
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;

    int32_t a[CELL_COUNT], b[CELL_COUNT], product[CELL_COUNT];
    int32_t diagonal[MAX_PASSES];
    for (int64_t pass = 0; pass < pass_count; ++pass) {
        uint32_t seed = 74755;
        for (size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            a[index] = (int32_t)(seed % 120u) - 60;
        }
        for (size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            b[index] = (int32_t)(seed % 120u) - 60;
        }

        for (size_t row = 0; row < ROWSIZE; ++row) {
            for (size_t column = 0; column < ROWSIZE; ++column) {
                int32_t sum = 0;
                for (size_t inner = 0; inner < ROWSIZE; ++inner)
                    sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                product[row * ROWSIZE + column] = sum;
            }
        }
        diagonal[pass] = product[(size_t)pass * ROWSIZE + (size_t)pass];
    }

    size_t required = 0;
    for (int64_t pass = 0; pass < pass_count; ++pass)
        required += decimal_width(diagonal[pass]) + 1;
    if (output == NULL || output_capacity < required) return -2;

    size_t position = 0;
    for (int64_t pass = 0; pass < pass_count; ++pass) {
        position = write_decimal(diagonal[pass], output, position);
        output[position++] = (uint8_t)'\n';
    }
    return (int64_t)position;
}
