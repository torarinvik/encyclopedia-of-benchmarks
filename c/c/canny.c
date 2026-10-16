#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 16
#define MAX_PIXELS (MAX_SIDE * MAX_SIDE)
#define NORM_SCALE 1048576LL
#define ANGLE_SCALE 1000000000LL
#define TAN_22_5_Q9 414213562LL

static const int64_t gaussian[5][5] = {
    {85321, 66110, 30754, 8589, 1440},
    {66110, 51225, 23829, 6655, 1116},
    {30754, 23829, 11085, 3096, 519},
    {8589, 6655, 3096, 865, 145},
    {1440, 1116, 519, 145, 24}
};

static const int sobel_x[3][3] = {
    {-1, 0, 1}, {-2, 0, 2}, {-1, 0, 1}
};
static const int sobel_y[3][3] = {
    {1, 2, 1}, {0, 0, 0}, {-1, -2, -1}
};

static uint64_t integer_sqrt(uint64_t value)
{
    uint64_t low = 1, high = value < (UINT64_C(1) << 32) ? value : (UINT64_C(1) << 32);
    if (value < 2) return value;
    while (low <= high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle + 1;
        else high = middle - 1;
    }
    return high;
}

static size_t clamp_coordinate(int coordinate, size_t side)
{
    if (coordinate < 0) return 0;
    if ((size_t)coordinate >= side) return side - 1;
    return (size_t)coordinate;
}

int64_t canny(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 1 + MAX_PIXELS) return -1;
    const int64_t side_value = values[0];
    if (side_value < 1 || side_value > MAX_SIDE) return -1;
    const size_t side = (size_t)side_value;
    const size_t pixels = side * side;
    if (length != pixels + 1) return -1;
    for (size_t i = 0; i < pixels; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    if (output_capacity < pixels || output == NULL) return -2;

    int64_t blurred[MAX_PIXELS] = {0};
    int64_t gradient_x[MAX_PIXELS] = {0};
    int64_t gradient_y[MAX_PIXELS] = {0};
    int64_t normalized_x[MAX_PIXELS] = {0};
    int64_t normalized_y[MAX_PIXELS] = {0};
    int64_t magnitude[MAX_PIXELS] = {0};
    uint8_t destination[MAX_PIXELS] = {0};

    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            int64_t total = 0;
            for (int ky = -4; ky <= 4; ++ky) {
                const size_t source_row = clamp_coordinate((int)row + ky, side);
                for (int kx = -4; kx <= 4; ++kx) {
                    const size_t source_column = clamp_coordinate((int)column + kx, side);
                    total += gaussian[ky < 0 ? -ky : ky][kx < 0 ? -kx : kx]
                           * values[1 + source_row * side + source_column];
                }
            }
            blurred[row * side + column] = total;
        }
    }

    int64_t maximum_x = 0, maximum_y = 0;
    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            int64_t total_x = 0, total_y = 0;
            for (int ky = -1; ky <= 1; ++ky) {
                const size_t source_row = clamp_coordinate((int)row + ky, side);
                for (int kx = -1; kx <= 1; ++kx) {
                    const size_t source_column = clamp_coordinate((int)column + kx, side);
                    const int64_t sample = blurred[source_row * side + source_column];
                    total_x += sample * sobel_x[ky + 1][kx + 1];
                    total_y += sample * sobel_y[ky + 1][kx + 1];
                }
            }
            if (total_x < 0) total_x = -total_x;
            if (total_y < 0) total_y = -total_y;
            const size_t offset = row * side + column;
            gradient_x[offset] = total_x;
            gradient_y[offset] = total_y;
            if (total_x > maximum_x) maximum_x = total_x;
            if (total_y > maximum_y) maximum_y = total_y;
        }
    }

    uint64_t maximum_magnitude = 0;
    for (size_t i = 0; i < pixels; ++i) {
        if (maximum_x != 0) normalized_x[i] = gradient_x[i] * 255 * NORM_SCALE / maximum_x;
        if (maximum_y != 0) normalized_y[i] = gradient_y[i] * 255 * NORM_SCALE / maximum_y;
        const uint64_t x = (uint64_t)normalized_x[i];
        const uint64_t y = (uint64_t)normalized_y[i];
        magnitude[i] = (int64_t)integer_sqrt(x * x + y * y);
        if ((uint64_t)magnitude[i] > maximum_magnitude) maximum_magnitude = (uint64_t)magnitude[i];
    }
    if (maximum_magnitude != 0) {
        for (size_t i = 0; i < pixels; ++i)
            magnitude[i] = magnitude[i] * 255 / (int64_t)maximum_magnitude;
    }

    for (size_t row = 1; row + 1 < side; ++row) {
        for (size_t column = 1; column + 1 < side; ++column) {
            const size_t offset = row * side + column;
            size_t before, after;
            if (normalized_y[offset] * ANGLE_SCALE < normalized_x[offset] * TAN_22_5_Q9) {
                before = offset - 1; after = offset + 1;
            } else if (normalized_x[offset] * ANGLE_SCALE <= normalized_y[offset] * TAN_22_5_Q9) {
                before = offset - side; after = offset + side;
            } else {
                before = offset + side - 1; after = offset - side + 1;
            }
            if (magnitude[offset] >= magnitude[before] && magnitude[offset] >= magnitude[after])
                destination[offset] = (uint8_t)magnitude[offset];
        }
    }

    for (size_t i = 0; i < pixels; ++i) {
        if (destination[i] >= 30) destination[i] = 255;
        else if (destination[i] <= 15) destination[i] = 0;
        else destination[i] = 128;
    }
    for (size_t row = 1; row + 1 < side; ++row) {
        for (size_t column = 1; column + 1 < side; ++column) {
            const size_t offset = row * side + column;
            if (destination[offset] == 128) {
                int connected = 0;
                for (int dy = -1; dy <= 1; ++dy)
                    for (int dx = -1; dx <= 1; ++dx)
                        if ((dx != 0 || dy != 0)
                            && destination[(size_t)((int)row + dy) * side + (size_t)((int)column + dx)] == 255)
                            connected = 1;
                destination[offset] = connected ? 255 : 0;
            }
        }
    }
    for (size_t i = 0; i < pixels; ++i) output[i] = destination[i];
    return (int64_t)pixels;
}
