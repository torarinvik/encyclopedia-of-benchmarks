/* Fixed-point sample adapter for the pinned Python Weddle-rule quadrature. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PANELS INT64_C(64)
#define MAX_STEP_NANOUNITS INT64_C(1000000000)
#define MAX_SAMPLE_MICRO INT64_C(1000000)
#define MAX_INPUT_LENGTH ((size_t)387)
#define INVALID_RESULT (-1.0e300)

double weddles_rule(const int64_t *values, size_t length) {
    if (values == NULL || length < 9 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t panels = values[0];
    const int64_t step_nanounits = values[1];
    if (panels < 1 || panels > MAX_PANELS || length != (size_t)(6 * panels + 3) ||
        step_nanounits < -MAX_STEP_NANOUNITS || step_nanounits > MAX_STEP_NANOUNITS) return INVALID_RESULT;

    const size_t sample_count = (size_t)(6 * panels + 1);
    double weighted_sum = 0.0;
    for (size_t index = 1; index + 1 < sample_count; ++index) {
        const int64_t sample_micro = values[index + 2];
        if (sample_micro < -MAX_SAMPLE_MICRO || sample_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        int64_t weight;
        if (index % 2 == 0 && index % 3 != 0) weight = 1;
        else if (index % 2 != 0 && index % 3 != 0) weight = 5;
        else if (index % 6 == 0) weight = 2;
        else weight = 6;
        weighted_sum += (double)weight * ((double)sample_micro / 1000000.0);
    }
    const int64_t first_micro = values[2];
    const int64_t last_micro = values[sample_count + 1];
    if (first_micro < -MAX_SAMPLE_MICRO || first_micro > MAX_SAMPLE_MICRO ||
        last_micro < -MAX_SAMPLE_MICRO || last_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
    const double step_size = (double)step_nanounits / 1000000000.0;
    return 0.3 * step_size * (weighted_sum + (double)first_micro / 1000000.0 + (double)last_micro / 1000000.0);
}
