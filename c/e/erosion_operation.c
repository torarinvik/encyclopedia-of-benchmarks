#include <stddef.h>
#include <stdint.h>

#define MAX_HEIGHT 6
#define MAX_WIDTH 6

int64_t erosion_operation(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 2 + MAX_HEIGHT * MAX_WIDTH) return -1;
    int64_t height = input[0], width = input[1];
    if (height < 1 || height > MAX_HEIGHT || width < 1 || width > MAX_WIDTH ||
        length != 2 + (size_t)(height * width)) return -1;
    for (size_t i = 2; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -1;
    int64_t result = 0;
    for (int64_t row = 0; row < height; ++row) for (int64_t col = 0; col < width; ++col) {
        int keep = input[2 + row * width + col] == 1;
        if (row == 0 || input[2 + (row - 1) * width + col] != 1) keep = 0;
        if (row + 1 == height || input[2 + (row + 1) * width + col] != 1) keep = 0;
        if (col == 0 || input[2 + row * width + col - 1] != 1) keep = 0;
        if (col + 1 == width || input[2 + row * width + col + 1] != 1) keep = 0;
        if (keep) result |= INT64_C(1) << (row * width + col);
    }
    return result;
}
