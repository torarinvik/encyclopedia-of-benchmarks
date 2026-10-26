#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { INPUT_COUNT = 18u, MAX_INPUT_LENGTH = 19u, OUTPUT_COUNT = 18u };
static const double PI = 3.14159265358979323846264338327950288;
static const double ENWINDOW_MAX = 0.030526638;

int64_t cbench_consumer_lame_mdct_short(const double *input, size_t input_length,
                                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i)
        if (!isfinite(input[i]) || input[i] < -32768.0 || input[i] > 32768.0) return -1;
    if (input_length != INPUT_COUNT) return -1;

    double coefficients[6][6];
    const double scale = 4.0 / 12.0;
    for (size_t i = 0; i < 3u; ++i) {
        const double w2 = cos(PI / 12.0 * ((double)i + 0.5)) * ENWINDOW_MAX / 32768.0 * scale;
        for (size_t m = 0; m < 6u; ++m) {
            coefficients[m][i] = w2 * cos((PI / 48.0) * (double)(2u * m + 1u) * (double)(4u * i + 14u));
            coefficients[m][i + 3u] = w2 * cos((PI / 48.0) * (double)(2u * m + 1u) * (double)(4u * i + 38u));
        }
    }

    double staged[OUTPUT_COUNT];
    for (int m = 5; m >= 0; --m) {
        for (int l = 2; l >= 0; --l) {
            const size_t base = 6u * (size_t)l;
            double sum = coefficients[m][0] * input[base];
            sum += coefficients[m][1] * input[base + 1u];
            sum += coefficients[m][2] * input[base + 2u];
            sum += coefficients[m][3] * input[base + 3u];
            sum += coefficients[m][4] * input[base + 4u];
            sum += coefficients[m][5] * input[base + 5u];
            staged[3u * (size_t)m + (size_t)l] = sum;
        }
    }
    if (output == NULL || output_capacity < OUTPUT_COUNT) return -2;
    for (size_t i = 0; i < OUTPUT_COUNT; ++i) output[i] = staged[i];
    return (int64_t)OUTPUT_COUNT;
}
