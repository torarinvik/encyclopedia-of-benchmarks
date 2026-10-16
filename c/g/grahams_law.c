#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define INVALID_RESULT (-1.0e300)

static double rounded_six(double value)
{
    if (!(value >= 0.0 && value <= 1.0e6)) return INVALID_RESULT;
    double scaled = value * 1000000.0;
    double lower = floor(scaled);
    double fraction = scaled - lower;
    if (fraction >= 0.499 && fraction <= 0.501) return INVALID_RESULT;
    if (fraction > 0.5) lower += 1.0;
    return lower / 1000000.0;
}

static double decode_positive(const int64_t *values, size_t index)
{
    double result;
    memcpy(&result, &values[index], sizeof(result));
    return isfinite(result) && result >= 1.0e-6 && result <= 1.0e6 ? result : 0.0;
}

double grahams_law(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 4 || values[0] < 0 || values[0] > 4) return INVALID_RESULT;
    int64_t operation = values[0];
    if ((operation == 0 && length != 3) || (operation != 0 && length != 4)) return INVALID_RESULT;
    double first = decode_positive(values, 1), second = decode_positive(values, 2);
    if (first == 0.0 || second == 0.0) return INVALID_RESULT;
    double result;
    if (operation == 0) result = sqrt(second / first);
    else {
        double third = decode_positive(values, 3);
        if (third == 0.0) return INVALID_RESULT;
        if (operation == 1) result = first * sqrt(third / second);
        else if (operation == 2) result = first / sqrt(third / second);
        else if (operation == 3) result = first / pow(second / third, 2.0);
        else result = pow(second / third, 2.0) / first;
    }
    return isfinite(result) ? rounded_six(result) : INVALID_RESULT;
}
