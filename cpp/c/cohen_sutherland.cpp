// Selected coordinate or acceptance flag from Cohen-Sutherland clipping.
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double SCALE = 1000000.0;
constexpr std::int64_t MAX_COORDINATE_MICRO = 1000000000;
enum { INSIDE = 0, LEFT = 1, RIGHT = 2, BOTTOM = 4, TOP = 8 };

int region_code(double x, double y, double x_min, double y_min, double x_max, double y_max) {
    int code = INSIDE;
    if (x < x_min) code |= LEFT;
    else if (x > x_max) code |= RIGHT;
    if (y < y_min) code |= BOTTOM;
    else if (y > y_max) code |= TOP;
    return code;
}
}

extern "C" double cohen_sutherland(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 9) return INVALID_RESULT;
    const auto selector = values[0];
    if (selector < 0 || selector > 4) return INVALID_RESULT;
    for (std::size_t i = 1; i < 9; ++i)
        if (values[i] < -MAX_COORDINATE_MICRO || values[i] > MAX_COORDINATE_MICRO)
            return INVALID_RESULT;

    const double x_min = static_cast<double>(values[1]) / SCALE;
    const double y_min = static_cast<double>(values[2]) / SCALE;
    const double x_max = static_cast<double>(values[3]) / SCALE;
    const double y_max = static_cast<double>(values[4]) / SCALE;
    if (x_min >= x_max || y_min >= y_max) return INVALID_RESULT;
    double x1 = static_cast<double>(values[5]) / SCALE;
    double y1 = static_cast<double>(values[6]) / SCALE;
    double x2 = static_cast<double>(values[7]) / SCALE;
    double y2 = static_cast<double>(values[8]) / SCALE;
    int code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
    int code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);

    bool accepted = false;
    for (;;) {
        if (code1 == INSIDE && code2 == INSIDE) { accepted = true; break; }
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
