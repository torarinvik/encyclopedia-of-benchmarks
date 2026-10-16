#include <math.h>

#define INVALID_RESULT (-1.0e300)

double sigmoid_without_inbuilt(double x, double slope) {
    if (!isfinite(x) || !isfinite(slope) || x < -10.0 || x > 10.0 ||
        slope < -10.0 || slope > 10.0) return INVALID_RESULT;
    return 1.0 / (1.0 + exp(-slope * x));
}

