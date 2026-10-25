#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t cbench_rsynth_natural_glottal_sample(const double *input, size_t n,
                                              double *output, size_t cap) {
    if (input == NULL || n == 0 || n > 3) return -1;
    for (size_t i = 0; i < n; ++i) if (!isfinite(input[i])) return -1;
    if (n != 2 || input[0] < 40.0 || input[0] > 263.0 || trunc(input[0]) != input[0] ||
        input[1] < 0.0 || input[1] > 299.0 || trunc(input[1]) != input[1]) return -1;
    long nopen = (long)input[0], sample_index = (long)input[1];
    float result = 0.0f;
    if (sample_index < nopen) {
        const int b_int = 1920000 / (int)(nopen * nopen);
        const float b = (float)b_int;
        float a = (float)((float)(b * (float)nopen) * 0.333);
        float vwave = 0.0f;
        for (long nper = 0; nper <= sample_index; ++nper) {
            a = a - b;
            vwave = vwave + a;
        }
        result = (float)((double)vwave * 0.028);
    }
    if (output == NULL || cap < 1) return -2;
    output[0] = (double)result;
    return 1;
}
