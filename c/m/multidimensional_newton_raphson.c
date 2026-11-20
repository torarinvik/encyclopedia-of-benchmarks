#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MNR_MIN_COORDINATE INT64_C(900)
#define MNR_MAX_COORDINATE INT64_C(1500)
#define MNR_MAX_UPDATES INT64_C(8)

static void mnr_store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t mnr_round_nano(double value) {
    const double magnitude = value < 0.0 ? -value : value;
    const int64_t rounded = (int64_t)floor(magnitude * 1000000000.0 + 0.5);
    return value < 0.0 ? -rounded : rounded;
}

int64_t multidimensional_newton_raphson(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1U || length > 4U) return -1;
    if (length != 3U) return -1;
    const int64_t x_milli = input[0];
    const int64_t y_milli = input[1];
    const int64_t updates = input[2];
    if (x_milli < MNR_MIN_COORDINATE || x_milli > MNR_MAX_COORDINATE
            || y_milli < MNR_MIN_COORDINATE || y_milli > MNR_MAX_COORDINATE
            || updates < 1 || updates > MNR_MAX_UPDATES) return -1;
    if (output == NULL || capacity < 16U) return -2;

    double x = (double)x_milli / 1000.0;
    double y = (double)y_milli / 1000.0;
    for (int64_t step = 0; step < updates; ++step) {
        const double f1 = x * x + y - 3.0;
        const double f2 = x + y * y - 3.0;
        const double determinant = 4.0 * x * y - 1.0;
        const double dx = (2.0 * y * f1 - f2) / determinant;
        const double dy = (2.0 * x * f2 - f1) / determinant;
        x -= dx;
        y -= dy;
    }

    mnr_store_i64_le(output, 0, mnr_round_nano(x));
    mnr_store_i64_le(output, 8, mnr_round_nano(y));
    return 16;
}
