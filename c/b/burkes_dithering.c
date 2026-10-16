#include <stddef.h>
#include <stdint.h>

static int trunc_div32(int value)
{
    return value < 0 ? -((-value) / 32) : value / 32;
}

int64_t burkes_dithering(const int64_t *input, size_t length)
{
    if (length < 3 || length > 150 || input == NULL) return -1;
    if (input[0] < 1 || input[0] > 7 || input[1] < 1 || input[1] > 254) return -1;
    const size_t side = (size_t)input[0], threshold = (size_t)input[1];
    if (length != 2 + 3 * side * side) return -1;
    for (size_t index = 2; index < length; ++index) {
        if (input[index] < 0 || input[index] > 255) return -1;
    }

    const size_t stride = side + 4;
    int errors[8 * 11] = {0};
    uint64_t white_pixels = 0;
    for (size_t y = 0; y < side; ++y) {
        for (size_t x = 0; x < side; ++x) {
            const size_t input_offset = 2 + 3 * (y * side + x);
            const int blue = (int)input[input_offset];
            const int green = (int)input[input_offset + 1];
            const int red = (int)input[input_offset + 2];
            const int gray = (114 * blue + 587 * green + 299 * red) / 1000;
            const int adjusted = gray + errors[y * stride + x];
            const int white = adjusted >= (int)threshold;
            const int current_error = adjusted - (white ? 255 : 0);
            if (white) white_pixels |= UINT64_C(1) << (y * side + x);
            errors[y * stride + x + 1] += trunc_div32(8 * current_error);
            errors[y * stride + x + 2] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x] += trunc_div32(8 * current_error);
            errors[(y + 1) * stride + x + 1] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x + 2] += trunc_div32(2 * current_error);
            if (x >= 1) errors[(y + 1) * stride + x - 1] += trunc_div32(4 * current_error);
            if (x >= 2) errors[(y + 1) * stride + x - 2] += trunc_div32(2 * current_error);
        }
    }
    return (int64_t)white_pixels;
}
