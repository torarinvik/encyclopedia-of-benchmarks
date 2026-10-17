#include <stddef.h>
#include <stdint.h>

enum {
    PIECEWISE_LINEAR_TRANSFORM_MAX_PIXELS = 256,
    PIECEWISE_LINEAR_TRANSFORM_MAX_INPUT_VALUES = 257
};

int64_t piecewise_linear_transform(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length == 0 ||
        length > PIECEWISE_LINEAR_TRANSFORM_MAX_INPUT_VALUES ||
        length > PIECEWISE_LINEAR_TRANSFORM_MAX_PIXELS) {
        return -1;
    }

    for (size_t i = 0; i < length; ++i) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }

    if (output == NULL || capacity < length) return -2;

    for (size_t i = 0; i < length; ++i) {
        const int64_t pixel = input[i];
        double transformed;
        if (0 <= pixel && pixel <= 100) {
            transformed = (50.0 / 100.0) * (double)pixel;
        } else if (100 <= pixel && pixel <= 180) {
            transformed = ((200.0 - 50.0) / (180.0 - 100.0)) *
                          ((double)pixel - 100.0) + 50.0;
        } else {
            transformed = ((255.0 - 200.0) / (255.0 - 180.0)) *
                          ((double)pixel - 180.0) + 200.0;
        }
        output[i] = (uint8_t)transformed;
    }

    return (int64_t)length;
}
