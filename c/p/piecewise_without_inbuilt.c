#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t piecewise_without_inbuilt(const double *input, size_t input_length,
                                  double *output, size_t output_capacity) {
    if (input == NULL || input_length != 1) return -1;
    const double x = input[0];
    if (!isfinite(x) || x < -10.0 || x > 10.0) return -1;

    const double y = x <= -0.5 ? 0.0 : (x < 0.5 ? x : 1.0);
    if (output == NULL || output_capacity < 1) return -2;
    output[0] = y;
    return 1;
}
