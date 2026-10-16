/* Selected coordinate or acceptance flag from Cohen-Sutherland clipping. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
#define MAX_COORDINATE_MICRO INT64_C(1000000000)

enum { INSIDE = 0, LEFT = 1, RIGHT = 2, BOTTOM = 4, TOP = 8 };

static int region_code(double x, double y, double x_min, double y_min,
                       double x_max, double y_max)
{
    int code = INSIDE;
    if (x < x_min) code |= LEFT;
    else if (x > x_max) code |= RIGHT;
    if (y < y_min) code |= BOTTOM;
    else if (y > y_max) code |= TOP;
    return code;
}

double cohen_sutherland(const int64_t *values, size_t length)
{
    if (values == NULL || length != 9) return INVALID_RESULT;
    const int64_t selector = values[0];
    if (selector < 0 || selector > 4) return INVALID_RESULT;
    for (size_t i = 1; i < 9; ++i) {
        if (values[i] < -MAX_COORDINATE_MICRO || values[i] > MAX_COORDINATE_MICRO)
            return INVALID_RESULT;
    }

    const double x_min = (double)values[1] / SCALE;
    const double y_min = (double)values[2] / SCALE;
    const double x_max = (double)values[3] / SCALE;
    const double y_max = (double)values[4] / SCALE;
    if (x_min >= x_max || y_min >= y_max) return INVALID_RESULT;
    double x1 = (double)values[5] / SCALE;
    double y1 = (double)values[6] / SCALE;
    double x2 = (double)values[7] / SCALE;
    double y2 = (double)values[8] / SCALE;
    int code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
    int code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);

    int accepted = 0;
    for (;;) {
        if (code1 == INSIDE && code2 == INSIDE) { accepted = 1; break; }
        if ((code1 & code2) != 0) break;

        const int code_out = code1 != INSIDE ? code1 : code2;
        double x, y;
        if ((code_out & TOP) != 0) {
            x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1);
            y = y_max;
        } else if ((code_out & BOTTOM) != 0) {
            x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1);
            y = y_min;
        } else if ((code_out & RIGHT) != 0) {
            y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1);
            x = x_max;
        } else {
            y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1);
            x = x_min;
        }
        if (code_out == code1) {
            x1 = x; y1 = y;
            code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
        } else {
            x2 = x; y2 = y;
            code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);
        }
    }

    if (selector == 4) return accepted ? 1.0 : 0.0;
    if (!accepted) return INVALID_RESULT;
    switch (selector) {
        case 0: return x1;
        case 1: return y1;
        case 2: return x2;
        default: return y2;
    }
}
