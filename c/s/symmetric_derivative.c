#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_X_NANOUNITS INT64_C(-6300000000)
#define MAX_X_NANOUNITS INT64_C(6300000000)
#define INVALID_RESULT (-1.0e300)
#define DEFAULT_STEP 1.0e-10

double symmetric_derivative(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t function_id = values[0];
    const int64_t x_nanounits = values[1];
    if ((function_id != 0 && function_id != 1) ||
        x_nanounits < MIN_X_NANOUNITS || x_nanounits > MAX_X_NANOUNITS) {
        return INVALID_RESULT;
    }

    const double x = (double)x_nanounits / 1000000000.0;
    const double upper = function_id == 0 ? sin(x + DEFAULT_STEP) : exp(x + DEFAULT_STEP);
    const double lower = function_id == 0 ? sin(x - DEFAULT_STEP) : exp(x - DEFAULT_STEP);
    return (upper - lower) / (2.0 * DEFAULT_STEP);
}
