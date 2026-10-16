#include <math.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_ABS_COORDINATE 1000000.0
#define DEGREE_FACTOR 57.2957795130823208768

static double round_to_two_decimals_away(double value) {
    if (value == 0.0) return value;
    double scaled = value * 100.0;
    double units = scaled < 0.0 ? trunc(scaled - 0.5) : trunc(scaled + 0.5);
    if (units == 0.0 && signbit(value)) return -0.0;
    return units / 100.0;
}

double rectangular_to_polar(double real, double imag, double component) {
    if (!isfinite(real) || !isfinite(imag) || !isfinite(component) ||
        real < -MAX_ABS_COORDINATE || real > MAX_ABS_COORDINATE ||
        imag < -MAX_ABS_COORDINATE || imag > MAX_ABS_COORDINATE ||
        (component != 0.0 && component != 1.0)) return INVALID_RESULT;
    if (component == 0.0) return round_to_two_decimals_away(sqrt(real * real + imag * imag));
    return round_to_two_decimals_away(atan2(imag, real) * DEGREE_FACTOR);
}
