#include <stddef.h>
#include <stdint.h>

static size_t write_run(uint8_t *output, size_t position, uint8_t byte, size_t count)
{
    for (size_t index = 0; index < count; ++index) output[position++] = byte;
    return position;
}

int64_t butterfly_pattern(int64_t n, uint8_t *output, size_t capacity)
{
    if (n < 1 || n > 45) return -1;
    const size_t side = (size_t)n;
    const size_t width = 2 * side - 1;
    const size_t required = width * width + 2 * side - 2;
    if (output == NULL || capacity < required) return -2;

    size_t position = 0;
    for (size_t count = 1; count < side; ++count) {
        if (position != 0) output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    if (position != 0) output[position++] = '\n';
    position = write_run(output, position, '*', width);
    for (size_t count = side - 1; count > 0; --count) {
        output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    return (int64_t)position;
}
