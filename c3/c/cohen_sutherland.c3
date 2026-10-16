module cohen_sutherland;

const double INVALID_RESULT = -1.0e300;
const double SCALE = 1000000.0;
const long MAX_COORDINATE_MICRO = 1000000000;
const int INSIDE = 0;
const int LEFT = 1;
const int RIGHT = 2;
const int BOTTOM = 4;
const int TOP = 8;

fn int region_code(double x, double y, double x_min, double y_min, double x_max, double y_max) {
    int code = INSIDE;
    if (x < x_min) code |= LEFT;
    else if (x > x_max) code |= RIGHT;
    if (y < y_min) code |= BOTTOM;
    else if (y > y_max) code |= TOP;
    return code;
}

fn double cohen_sutherland(long* values, usz length) @export("cohen_sutherland") {
    if (values == null || length != 9) return INVALID_RESULT;
    long selector = values[0];
    if (selector < 0 || selector > 4) return INVALID_RESULT;
    for (usz i = 1; i < 9; i++) {
        if (values[i] < -MAX_COORDINATE_MICRO || values[i] > MAX_COORDINATE_MICRO)
            return INVALID_RESULT;
    }
    double x_min = (double)values[1] / SCALE;
    double y_min = (double)values[2] / SCALE;
    double x_max = (double)values[3] / SCALE;
    double y_max = (double)values[4] / SCALE;
    if (x_min >= x_max || y_min >= y_max) return INVALID_RESULT;
    double x1 = (double)values[5] / SCALE;
    double y1 = (double)values[6] / SCALE;
    double x2 = (double)values[7] / SCALE;
    double y2 = (double)values[8] / SCALE;
    int code1 = region_code(x1, y1, x_min, y_min, x_max, y_max);
    int code2 = region_code(x2, y2, x_min, y_min, x_max, y_max);
    bool accepted = false;
    while (true) {
        if (code1 == INSIDE && code2 == INSIDE) { accepted = true; break; }
        if ((code1 & code2) != 0) break;
        int code_out = code1 != INSIDE ? code1 : code2;
        double x;
        double y;
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
    if (selector == 0) return x1;
    if (selector == 1) return y1;
    if (selector == 2) return x2;
    return y2;
}
