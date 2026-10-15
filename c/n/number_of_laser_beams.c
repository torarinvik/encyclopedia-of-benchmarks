/* Count adjacent nonempty-row device pairs in a fixed-width binary bank. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)

int64_t number_of_laser_beams(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_CELLS + 2) return -1;
    if (input[0] < 1 || input[0] > MAX_DIMENSION ||
        input[1] < 1 || input[1] > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)input[0], columns = (size_t)input[1];
    if (length != rows * columns + 2) return -1;

    int64_t previous_devices = 0, beams = 0;
    for (size_t row = 0; row < rows; ++row) {
        int64_t devices = 0;
        for (size_t column = 0; column < columns; ++column) {
            const int64_t cell = input[2 + row * columns + column];
            if (cell != 48 && cell != 49) return -1;
            if (cell == 49) ++devices;
        }
        if (devices != 0) {
            beams += devices * previous_devices;
            previous_devices = devices;
        }
    }
    return beams;
}
